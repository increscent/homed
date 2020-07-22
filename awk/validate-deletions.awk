# Validate Deletions
# Purpose: We only need to delete files that actually exist.
# So if the file is not contained in the 'branch.txt' listing then
# it probably doesn't exist. The one exception to this rule is if
# it were copied in the 'copy additions' step.

BEGIN {
    FS = "\t";

    # both input files must be sorted
    # branch is really a list of deletions
    base_file = ARGV[1];
    branch_file = ARGV[2];

    read_base();
    read_branch();

    while (base_read_result > 0 && branch_read_result > 0) {
        if (base_name == branch_name) {
            print branch_name;
            read_base();
            read_branch();
        }
        else if (base_name > branch_name) {
            # base does not have branch line
            read_branch();
        }
        else if (branch_name > base_name) {
            # branch does not have base line
            read_base();
        }
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
