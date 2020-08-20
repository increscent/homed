# Create Branch
# Purpose: this program copies valid file hashes from the base to the branch.
# It takes a long time to hash all the files, so we only want to hash the ones
# that we need to.

# base_time2/branch_time2 is the time the file was added to this system

BEGIN {
    FS = "\t";

    # both input files must be sorted
    base_file = ARGV[1];
    branch_file = ARGV[2];

    if (length(dir) == 0) {
        print "No directory" > "/dev/stderr";
        exit 1;
    }

    read_base();
    read_branch();

    # If we are adding a new file to the branch then set the added time to
    # the current time, rather than the file's modified time.
    # If the file had previously been deleted then the new
    # time must be newer than the deleted time.

    while (base_read_result > 0 && branch_read_result > 0) {
        if (base_name == branch_name) {
            if (base_time == branch_time        \
                && base_size == branch_size     \
                && base_type == branch_type     \
                && length(base_hash) != 0       \
            ) {
                # hash is correct
                print_base();
            }
            else {
                branch_time2 = length(base_time2) == 0 ? cur_time : base_time2;
                branch_hash = branch_type == "f" ? get_hash(branch_name) : "";
                print_branch();
            }
            read_base();
            read_branch();
        }
        else if (base_name > branch_name) {
            # base does not have branch line
            branch_time2 = cur_time;
            branch_hash = branch_type == "f" ? get_hash(branch_name) : "";
            print_branch();
            read_branch();
        }
        else if (branch_name > base_name) {
            # branch does not have base line
            read_base();
        }
    }

    while (branch_read_result > 0) {
        # base does not have branch line
        branch_time2 = cur_time;
        branch_hash = branch_type == "f" ? get_hash(branch_name) : "";
        print_branch();
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

function get_hash(file) {
    sprintf("shasum -a 256 \"%s/%s\"", dir, file) | getline output;
    split(output, hash_array, " ");
    return hash_array[1];
}
