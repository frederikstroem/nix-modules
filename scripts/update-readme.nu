#!/usr/bin/env nu

use std/log

# Run `nix-options-doc` and get JSON output.
def get_options_data []: nothing -> list<record> {
    log info "Executing nix-options-doc to retrieve module options"
    let output = (nix-options-doc --path . --strip-prefix -f json | complete)

    if $output.exit_code != 0 {
        log debug $"stderr: ($output.stderr)"
        error make {
            msg: $"nix-options-doc failed with exit code ($output.exit_code): ($output.stderr)"
        }
    }

    if ($output.stdout | str trim | is-empty) {
        log warning "nix-options-doc returned empty output"
        return []
    }

    try {
        let parsed = ($output.stdout | from json)
        log debug $"Successfully parsed JSON with ($parsed | length) options"
        # Sort options by name to ensure deterministic output
        $parsed | sort-by name
    } catch { |e|
        error make {
            msg: $"Failed to parse nix-options-doc JSON output: ($e.msg)"
        }
    }
}

# Convert options data to markdown format.
def generate_options_markdown []: list<record> -> string {
    log debug "Generating markdown documentation…"

    let options = $in

    if ($options | length) == 0 {
        log debug "No options to process, returning empty state message"
        return "# 🎛️ Module Options\n\n*No module options found.*\n"
    }

    log debug $"Processing ($options | length) options for markdown generation"
    mut markdown_lines = ["# 🎛️ Module Options"]

    for option in $options {
        log debug $"Processing option: ($option.name)"

        # Create the header with option name and file link.
        let file_link = $"($option.file_path)#L($option.line_number)"
        let header = $"## [`($option.name)`]\(($file_link)\)"
        $markdown_lines = ($markdown_lines | append $header)

        # Add description if it exists.
        if ($option.description | is-not-empty) {
            let description = $option.description | str trim
            $markdown_lines = ($markdown_lines | append $description)
            $markdown_lines = ($markdown_lines | append "")
        } else {
            log debug "  No description available"
        }

        # Add type information.
        log debug $"  Type: ($option.nix_type)"
        $markdown_lines = ($markdown_lines | append $"**Type:** `($option.nix_type)`")
        $markdown_lines = ($markdown_lines | append "")

        # Add default value if it exists and is not null.
        if ($option.default_value | is-not-empty) and ($option.default_value != null) {
            log debug $"  Default value: ($option.default_value)"
            $markdown_lines = ($markdown_lines | append $"**Default:** `($option.default_value)`")
            $markdown_lines = ($markdown_lines | append "")
        } else {
            log debug "  No default value"
        }

        # Add example if it exists.
        if ($option.example | is-not-empty) {
            log debug $"  Example: ($option.example)"
            $markdown_lines = ($markdown_lines | append $"**Example:** `($option.example)`")
            $markdown_lines = ($markdown_lines | append "")
        } else {
            log debug "  No example provided"
        }
    }

    return ($markdown_lines | str join "\n")
}

# Update README.md with new options documentation.
def update_readme [new_options_content: string]: nothing -> nothing {
    log debug "Updating README.md…"

    let readme_path = "README.md"

    log debug $"Checking for README.md at: ($readme_path)"
    if not ($readme_path | path exists) {
        error make {
            msg: $"README.md not found at ($readme_path)"
        }
    }

    log debug "Reading current README.md content"
    let current_content = (open $readme_path --raw)
    let lines = ($current_content | lines)
    log debug $"README.md has ($lines | length) lines"

    # Find the "# 🎛️ Module Options" marker line.
    let marker = "# 🎛️ Module Options"
    log debug $"Searching for marker: '($marker)'"
    let marker_index = ($lines | enumerate | where item == $marker | first | get index?)

    if ($marker_index | is-empty) {
        error make {
            msg: $"Could not find '($marker)' marker in README.md"
        }
    }

    log debug $"Found options marker at line ($marker_index + 1)"

    # Keep everything before the marker line.
    let content_before_marker = ($lines | take $marker_index | str join "\n")
    log debug $"Content before marker: ($content_before_marker | str length) chars"

    # Combine the content before marker with the new options content.
    let new_content = if ($content_before_marker | is-empty) {
        $new_options_content
    } else {
        $"($content_before_marker)\n($new_options_content)"
    }

    log debug $"Final content length: ($new_content | str length) chars"

    # Write the updated content back to README.md.
    log debug "Writing updated content to README.md"
    $new_content | save -f $readme_path

    log info "Successfully updated README.md with new options documentation"
}

def main [] {
    log info "Starting README.md options documentation update"

    # Get options data from nix-options-doc.
    let options_data = get_options_data

    log info $"Found ($options_data | length) module options"

    # Generate markdown content.
    let options_markdown = $options_data | generate_options_markdown

    # Update README.md.
    update_readme $options_markdown

    log info "README.md update completed successfully! 🚀"
}
