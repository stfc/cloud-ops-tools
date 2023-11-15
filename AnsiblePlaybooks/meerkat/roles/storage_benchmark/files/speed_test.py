import time
import random
import os
import argparse

def setup():
    """
    Sets up inital variables for how many files to write, the size of the files, and where to write them to
    :return n: number of files to files generate
    :return size: size of files to generate (in MB)
    :return args.p: path to where to write files to
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", help="Number of files to write to (in MB)")
    parser.add_argument("-s", help="Size of each file")
    parser.add_argument("-p", help="Path to where files should be written")
    args = parser.parse_args()

    if not args.p:
        args.p = "./"
    if args.p[-1] != "/":
        args.p = args.p + "/"
    n = int(args.n)
    size = int(float(args.s) * 57400) # 57400 ~= 1MB
    return n, size, args.p


def generate_data(length):
    """
    Generates random data
    :param length: size of data to generate (in MB)
    :return: list of strings of random data
    """
    random.seed(33)
    print(length)
    return [str(random.random()) for i in range(length)]

def generate_files(n, path):
    """
    Generates files to write data to
    :param n: number of files to generate
    :param path: path to directory to make files in
    :return: list of paths to files
    """
    print(path)
    return [path + "data" + str(i) + ".txt" for i in range(n)]

def write_to_file(paths, data):
    """
    write data to file in path
    :param paths: list of paths to file to write to
    :param data: data to write to file
    """
    for path in paths:
        data_file = open(path, 'w')
        data_file.writelines(data)
        data_file.close()

def read_files(paths):
    """
    reads in data from file on path
    :param path: list of paths to file to read
    """
    for path in paths:
        data_file = open(path, 'r')
        _ = data_file.readlines()
        data_file.close()

def remove_files(paths):
    """
    removes files from path
    :param paths: list of paths of files to remove
    """
    for path in paths:
        os.remove(path)

def main():
    """
    Main
    """
    n, size, folder_path = setup()
    data = generate_data(size)
    paths = generate_files(n, folder_path)

    #Time write speed
    t1 = time.time()
    write_to_file(paths, data)
    t2 = time.time()
    #Time read speed
    read_files(paths)
    t3 = time.time()

    file_size = os.stat(paths[0]).st_size / (1024 * 1024)
    remove_files(paths)

    print("WRITING:")
    print("Written {} files of size {} MB".format(n, round(file_size,3)))
    print("Time taken: ", round(t2-t1, 3), " secs")
    print("Write speed: ", round((n * file_size) / (t2 - t1), 3), " MB/s")
    print("READING:")
    print("Time taken: ", round(t3-t2, 3), " secs")
    print("Read speed: ", round((n * file_size) / (t3 - t2), 3), " MB/s")

main()

