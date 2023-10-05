import time
import random
import os
import argparse


def setup():
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--n", help="Number of files to write to (in MB)")
    parser.add_argument("-size", "--size", help="Size of each file")
    args = parser.parse_args()
    n = int(args.n)
    size = int(float(args.size) * 57400) # 57400 ~= 1MB
    return n, size


def generate_data(length):
    random.seed(33)
    return [str(random.random()) for i in range(length)]

def generate_files(n):
    return ["data" + str(i) + ".txt" for i in range(n)]

def write_to_file(path, data):
    data_file = open(path, 'w')
    data_file.writelines(data)
    data_file.close()

def read_files(path):
    data_file = open(path, 'r')
    _ = data_file.readlines()
    data_file.close()

def remove_files(paths):
    for path in paths:
        os.remove(path)


def main():
    n, size = setup()
    data = generate_data(size)
    paths = generate_files(n)

    t1 = time.time()
    for i in range(n):
        write_to_file(paths[i], data)
    t2 = time.time()

    for i in range(n):
        read_files(paths[i])
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
