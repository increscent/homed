# Copy Additions
# Purpose: once we have source/destination pairs of files to copy, we need to print the cp/mv
# command depending on whether the source is used only once and will be deleted.
# We also need to use the mkdir command in case the destination directory hasn't
# yet been created.

BEGIN {
    FS = "\t";

    # both input files must be sorted
    # base file is really additions pairing file
    # branch file is deletions
    base_file = ARGV[1];
    branch_file = ARGV[2];

    if (length(dir) == 0) {
        print "No directory" > "/dev/stderr";
        exit 1;
    }

    read_branch();
    while (branch_read_result > 0) {
        deletions[branch_name] = 1;
        read_branch();
    }

    i = 1;
    read_base();
    while (base_read_result > 0) {
        sources[i] = base_source;
        dests[i] = base_dest;

        source_count[base_source] += 1;

        i += 1;

        read_base();
    }

    for (i = 1; i <= length(sources); ++i) {
        printf("mkdir -p $(dirname \"%s/%s\")\n", dir, dests[i]);

        if (sources[i] in deletions && source_count[sources[i]] == 1) {
            printf("mv -u \"%s/%s\" \"%s/%s\"\n", dir, sources[i], dir, dests[i]);
        } else {
            printf("cp -a \"%s/%s\" \"%s/%s\"\n", dir, sources[i], dir, dests[i]);
        }
    }
}

function read_base() {
    base_read_result = getline < base_file;
    base_source = $1;
    base_dest = $2;
}

function read_branch() {
    branch_read_result = getline < branch_file;
    branch_name = $1;
    branch_time = $2;
    branch_size = $3;
    branch_type = $4;
    branch_time2 = $5;
    branch_hash = $6;
}
