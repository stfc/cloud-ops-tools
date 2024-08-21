/// Computes a forward FFT of size nx x ny x nz (1024 x 1024 x 10)
use ndarray::{Array2};
use ndrustfft::{ndfft_r2c, Complex, R2cFftHandler, ndfft_r2c_par};
use rand::Rng;
use std::time::Instant;
use num_cpus;

/// Values for the benchmarks
struct BenchmarkValues {
    // Vector of 2D arrays for input data
    data: Vec<Array2::<f64>>,
    // Vector of 2D arrays for FFT result
    results: Vec<Array2::<Complex<f64>>>,
    // Vector for FFT handler
    fft_handler: Vec<R2cFftHandler::<f64>>,
    // Number of iterations counter
    iterations: f64,
    // Time to run the benchmark
    time_in_secs: f64,
    // Time the benchmark has run for
    time_taken: f64,
    // Start time of the benchmark
    start: Instant,
}
impl BenchmarkValues {
    /// Setup data array with random data
    fn setup_data(&mut self) {
        let mut rng = rand::thread_rng();
        for i in 0..self.data.len(){
            for v in self.data[i].iter_mut() {
                *v = rng.gen::<f64>();
            }
        }
    }
    
    /// Single core fft of data for a given length of time    
    fn single_core(&mut self) {
        self.start = Instant::now();
        while self.time_taken < (self.time_in_secs * 1000.0)  {
            for i in 0..self.data.len() {
                ndfft_r2c(
                    &self.data[i].view(),
                    &mut self.results[i].view_mut(),
                    &mut self.fft_handler[i],
                    0,
                );
            }
            self.time_taken = self.start.elapsed().as_millis() as f64;
            self.iterations += 1.0;
        }
    }

    /// Multicore fft of data for a given length of time
    fn multi_core(&mut self) {
        self.start = Instant::now();
        while self.time_taken < (self.time_in_secs * 1000.0)  {
            for i in 0..self.data.len() {
                ndfft_r2c_par(
                    &self.data[i].view(),
                    &mut self.results[i].view_mut(),
                    &mut self.fft_handler[i],
                    0,
                );
            }
            self.time_taken = self.start.elapsed().as_millis() as f64;
            self.iterations += 1.0;
        }
    }
    
    /// Print benchmark results
    fn print_results(&self) {
        println!("--------------------------");
        println!("Time taken: {}", self.time_taken / 1000.0);
        println!("Completed iterations: {}", self.iterations);
        println!("Iterations per second: {:.3}", self.iterations / (self.time_taken / 1000.0));
        println!("Number of cores {}", num_cpus::get());
    }
}


fn main() {
    // Data array dimensions
    let nx = 1024;
    let ny = 1024;
    let nz = 10;

    // Single core benchmark parameters
    let mut single_core_values = BenchmarkValues {
        data: vec![Array2::<f64>::zeros((nx, ny)); nz],
        results: vec![Array2::<Complex<f64>>::zeros((nx / 2 + 1, ny)); nz],
        fft_handler: vec![R2cFftHandler::<f64>::new(nx); nz],
        iterations: 0.0,
        time_in_secs: 180.0,
        time_taken: 0.0,
        start: Instant::now(),
    };

    // Multicore benchmark parameters
    let mut multi_core_values = BenchmarkValues {
        data: vec![Array2::<f64>::zeros((nx, ny)); nz],
        results: vec![Array2::<Complex<f64>>::zeros((nx / 2 + 1, ny)); nz],
        fft_handler: vec![R2cFftHandler::<f64>::new(nx); nz],
        iterations: 0.0,
        time_in_secs: single_core_values.time_in_secs,
        time_taken: 0.0,
        start: Instant::now(),
    };

    // Run single core benchmark
    single_core_values.setup_data();
    single_core_values.single_core();
    single_core_values.print_results();

    // Run Multicore benchmark
    multi_core_values.setup_data();
    multi_core_values.multi_core();
    multi_core_values.print_results();
}
