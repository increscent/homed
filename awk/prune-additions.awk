BEGIN {
    FS = "\t";

    # both input files must be sorted
    # base is deletions
    # branch is additions
    base_file = ARGV[1];
    branch_file = ARGV[2];

    read_base();
    read_branch();

    while (base_read_result > 0 && branch_read_result > 0) {
        if (base_name == branch_name) {
            read_base();
            read_branch();
        }
        else if (base_name > branch_name) {
            # base does not have branch line
            print_branch();
            read_branch();
        }
        else if (branch_name > base_name) {
            read_base();
        }
    }

    while (branch_read_result > 0) {
        # base does not have branch line
        print_branch();
        read_branch();
    }
}

function print_base() {
    printf("%s\t%s\t%s\t%s\t%s\n", base_name, base_time, base_size, base_type, base_hash);
}

function print_branch() {
    printf("%s\t%s\t%s\t%s\t%s\n", branch_name, branch_time, branch_size, branch_type, branch_hash);
}

function read_base() {
    base_read_result = getline < base_file;
    base_name = $1;
    base_time = $2;
    base_size = $3;
    base_type = $4;
    base_hash = $5;
}

function read_branch() {
    branch_read_result = getline < branch_file;
    branch_name = $1;
    branch_time = $2;
    branch_size = $3;
    branch_type = $4;
    branch_hash = $5;
}
