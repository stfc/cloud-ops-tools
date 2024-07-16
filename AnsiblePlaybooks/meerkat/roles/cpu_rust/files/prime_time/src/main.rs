use std::time::Instant;
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use num_cpus;


fn is_prime(n: u32) -> bool {
    // checks if a number if prime
    (2..=n / 2).all(|i| n % i != 0)
}

struct BenchmarkValues {
    max_value: u32,
    iterations: f64,
    time_in_secs: u32,
    time_taken: f64,
    start: Instant,
}
impl BenchmarkValues {
    fn single_core(&self) -> usize {
        // single core run of is_prime
        let primes: Vec<u32> = (2..self.max_value).filter(|n| is_prime(*n)).collect();
        primes.len()
    }

    fn multi_core(&self) -> usize {
        // multicore run of is_prime
        let primes: Vec<u32> = (2..self.max_value)
        .into_par_iter()
        .filter(|n| is_prime(*n))
        .collect();
        primes.len()
    }

    fn print_results(&self) {
        // prints test results
        println!("--------------------------------------------");
        println!("Time taken: {}", self.time_taken / 1000.0);
        println!("Completed iterations: {}", self.iterations);
        println!("Iterations per second: {:.3}", self.iterations / (self.time_taken / 1000.0) );
        println!("Number of cores: {}", num_cpus::get());
    }

    fn run_single_core(&mut self) {
        // run single core prime test for a given length of time
        self.start = Instant::now();
        while self.time_taken < (self.time_in_secs * 1000) as f64 {
            let _primes = self.single_core();
            self.time_taken = self.start.elapsed().as_millis() as f64;
            self.iterations += 1.0;
        }   
    }

    fn run_multi_core(&mut self) {
        // run multicore prime test for given length of time
        self.start = Instant::now();
        while self.time_taken < (self.time_in_secs * 1000) as f64 {
            let _primes = self.multi_core();
            self.time_taken = self.start.elapsed().as_millis() as f64;
            self.iterations += 1.0;
        }
    }
}

fn main() {

    // Single core parameters
    let mut single_core_values = BenchmarkValues {
        max_value: 100_000,
        iterations: 0.0,
        time_in_secs: 180,
        time_taken: 0.0,
        start: Instant::now(),
    };

    // multicore parameters
    let mut multi_core_values = BenchmarkValues {
        max_value: single_core_values.max_value,
        iterations: 0.0,
        time_in_secs: single_core_values.time_in_secs,
        time_taken: 0.0,
        start: Instant::now(),
    };

    // single core benchmark
    single_core_values.run_single_core();
    single_core_values.print_results();

    // multicore benchmark
    multi_core_values.run_multi_core();
    multi_core_values.print_results();
}