# Render only the managed orchestration block; leave surrounding user rules intact.
# Inputs are read-only. Installers validate this output before changing any target.
BEGIN {
    begin_marker = "<!-- codex-orchestrator:begin -->"
    end_marker = "<!-- codex-orchestrator:end -->"
    while ((getline line < replacement_path) > 0) {
        sub(/\r$/, "", line)
        replacement = replacement line "\n"
    }
    close(replacement_path)
    while ((getline line < legacy_path) > 0) {
        sub(/\r$/, "", line)
        legacy[++legacy_count] = line
    }
    close(legacy_path)
    if (replacement == "" || legacy_count == 0) {
        print "Missing instruction migration sources." > "/dev/stderr"
        exit 2
    }
}
{
    sub(/\r$/, "")
    lines[++count] = $0
    if ($0 == begin_marker) { begins++; first = count }
    if ($0 == end_marker) { ends++; last = count }
}
END {
    if (replacement == "" || legacy_count == 0) exit 2
    if (begins != ends || begins > 1 || (begins == 1 && first >= last)) {
        print "Invalid managed instruction markers. Follow guides/migration.md; no files changed." > "/dev/stderr"
        exit 2
    }
    for (i = 1; i <= count; i++) {
        if (begins == 1 && i == first) {
            if (!installed) output = output replacement
            installed = 1
            i = last
            continue
        }
        match_legacy = (lines[i] == legacy[1] && i + legacy_count - 1 <= count)
        if (match_legacy) {
            for (j = 1; j <= legacy_count; j++) {
                if (lines[i + j - 1] != legacy[j]) { match_legacy = 0; break }
            }
        }
        if (match_legacy) {
            if (!installed) output = output replacement
            installed = 1
            i += legacy_count - 1
            continue
        }
        output = output lines[i] "\n"
        residual = residual lines[i] "\n"
    }
    if (residual ~ /sol-orchestrator/ && residual ~ /GPT-5[.]6|gpt-5[.]6/) {
        print "Customized legacy instructions require manual reconciliation. Follow guides/migration.md; no files changed." > "/dev/stderr"
        exit 2
    }
    if (!installed) {
        if (output != "") output = output "\n"
        output = output replacement
    }
    printf "%s", output
}
