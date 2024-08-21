/// Calculates primes up to a certain value for a given length of time
use std::time::Instant;
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use num_cpus;

/// checks if a number if prime
fn is_prime(n: u32) -> bool {
    (2..=n / 2).all(|i| n % i != 0)
}

/// Values for the benchmarks
struct BenchmarkValues {
    // Maximum value to check primes up to
    max_value: u32,
    // Counter for number of iterations
    iterations: f64,
    // Period to run benchmark
    time_in_secs: u32,
    // Time the benchmark has run for
    time_taken: f64,
    // Start time for benchmark
    start: Instant,
}
impl BenchmarkValues {
    /// Calls single core run of is_prime
    fn single_core(&self) -> usize {
        let primes: Vec<u32> = (2..self.max_value).filter(|n| is_prime(*n)).collect();
        primes.len()
    }
    
    /// Calls multi core run of is_prime
    fn multi_core(&self) -> usize {
        let primes: Vec<u32> = (2..self.max_value)
        .into_par_iter()
        .filter(|n| is_prime(*n))
        .collect();
        primes.len()
    }
    
    /// Prints benchmark results
    fn print_results(&self) {
        println!("--------------------------------------------");
        println!("Time taken: {}", self.time_taken / 1000.0);
        println!("Completed iterations: {}", self.iterations);
        println!("Iterations per second: {:.3}", self.iterations / (self.time_taken / 1000.0) );
        println!("Number of cores: {}", num_cpus::get());
    }
    
    /// Run single core prime test for a given length of time
    fn run_single_core(&mut self) {
        self.start = Instant::now();
        while self.time_taken < (self.time_in_secs * 1000) as f64 {
            let _primes = self.single_core();
            self.time_taken = self.start.elapsed().as_millis() as f64;
            self.iterations += 1.0;
        }   
    }
    
    /// Run multicore prime test for given length of time
    fn run_multi_core(&mut self) {
        self.start = Instant::now();
        while self.time_taken < (self.time_in_secs * 1000) as f64 {
            let _primes = self.multi_core();
            self.time_taken = self.start.elapsed().as_millis() as f64;
            self.iterations += 1.0;
        }
    }
}

fn main() {
    // Setting up single core  benchmark parameters
    let mut single_core_values = BenchmarkValues {
        max_value: 100_000,
        iterations: 0.0,
        time_in_secs: 180,
        time_taken: 0.0,
        start: Instant::now(),
    };

    // Setting up Multi core benchmark parameters
    let mut multi_core_values = BenchmarkValues {
        max_value: single_core_values.max_value,
        iterations: 0.0,
        time_in_secs: single_core_values.time_in_secs,
        time_taken: 0.0,
        start: Instant::now(),
    };

    // Run single core benchmark
    single_core_values.run_single_core();
    single_core_values.print_results();

    // Run multi core benchmark
    multi_core_values.run_multi_core();
    multi_core_values.print_results();
}