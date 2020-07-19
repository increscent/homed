BEGIN {
    FS = "\t";

    # both input files must be sorted
    base_file = ARGV[1];
    brch_file = ARGV[2];

    read_base();
    read_brch();

    while (base_read_result > 0 && brch_read_result > 0) {
        if (base_name == brch_name) {
            read_base();
            read_brch();
        }
        if (base_name > brch_name) {
            # base does not have branch line
            read_brch();
        }
        if (brch_name > base_name) {
            # branch does not have base line
            print_base();
            read_base();
        }
    }

    while (base_read_result > 0) {
        print_base();
        read_base();
    }
}

function print_base() {
    printf("%s\t%s\t%s\t%s\t%s\n", base_name, base_time, base_size, base_type, base_hash);
}

function print_brch() {
    printf("%s\t%s\t%s\t%s\t%s\n", brch_name, brch_time, brch_size, brch_type, brch_hash);
}

function read_base() {
    base_read_result = getline < base_file;
    base_name = $1;
    base_time = $2;
    base_size = $3;
    base_type = $4;
    base_hash = $5;
}

function read_brch() {
    brch_read_result = getline < brch_file;
    brch_name = $1;
    brch_time = $2;
    brch_size = $3;
    brch_type = $4;
    brch_hash = $5;
}
