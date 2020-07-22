BEGIN {
    FS = "\t";

    # both input files must be sorted
    # branch file is really additions file
    base_file = ARGV[1];
    branch_file = ARGV[2];

    if (length(dir) == 0) {
        print "No directory" > "/dev/stderr";
        exit 1;
    }

    read_base();
    while (base_read_result > 0) {
        if (base_type == "f" && length(base_hash) > 0) {
            files[base_hash] = base_name;
        }
        read_base();
    }

    read_branch();
    while (branch_read_result > 0) {
        if (branch_type == "f" && length(branch_hash) > 0 && branch_hash in files) {
            printf("mkdir -p $(dirname \"%s/%s\")\n", dir, branch_name);
            printf("cp -a \"%s/%s\" \"%s/%s\"\n", dir, files[branch_hash], dir, branch_name);
        }
        read_branch();
    }
}

function print_base() {
    printf("%s\t%s\t%s\t%s\t%s\t%s\n", base_name, base_time, base_size, base_type, base_time2, base_hash);
}

function print_branch() {
    printf("%s\t%s\t%s\t%s\t%s\t%s\n", branch_name, branch_time, branch_size, branch_type, branch_time2, branch_hash);
}

function read_base() {
    base_read_result = getline < base_file;
    base_name = $1;
    base_time = $2;
    base_size = $3;
    base_type = $4;
    base_time2 = $5;
    base_hash = $6;
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
