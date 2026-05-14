package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:sys/windows"


main :: proc() {
	example :: proc(t: f64) -> f64 {
		return 250.0 * math.sin(0.2 * t)
	}

	context.logger = log.create_console_logger()

	windows.SetConsoleOutputCP(.UTF8)

	a :: 0.0
	b :: 5.0 * math.PI

	n :: 9
	result := simpson38(example, a, b, n)
	// result, m, k := adaptive2_simpson38(example, a, b)
	// n := k - 1
	// result, n := adaptive_simpson38(example, a, b)

	fmt.println("--- Simpson's 3/8 Rule ---")
	fmt.printf("Function: y = 250 * sin(0.2 * t)\n")
	fmt.printf("Interval: [%.2f, %.2f] (0 to 5*pi)\n", a, b)
	fmt.printf("Number of subintervals (n): %d\n\n", n)
	fmt.printf("Calculated value: %f\n", result)
	fmt.printf("Midpoint value:   %f\n", 1.0 / (b - a) * result)
}


Integrand :: proc(t: f64) -> f64


// Function to calculate the integral using Simpson's 3/8 rule.
simpson38 :: proc(f: Integrand, a: f64, b: f64, n: uint) -> f64 {
	// For Simpson's 3/8 rule, the number of sub-intervals must be a multiple of 3.
	if n % 3 != 0 {
		fmt.panicf("number of sub-intervals 'n' must be a multiple of 3, got %d", n)
	}

	h := (b - a) / f64(n)
	sum := f(a) + f(b)

	for i in 1 ..< n {
		// Every third node is multiplied by 2, all other nodes by 3.
		sum += f(a + f64(i) * h) * (2.0 if i % 3 == 0 else 3.0)
	}

	return (3.0 * h / 8.0) * sum
}


// Adaptive function to calculate 'n' dynamically based on desired precision (epsilon).
adaptive_simpson38 :: proc(
	f: Integrand,
	a, b: f64,
	epsilon: f64 = 1e-6,
) -> (
	result: f64,
	final_n: uint,
) {
	MAX_ITERATIONS :: 10_000_000

	// Starting with the minimum required intervals for 3/8 rule.
	n := uint(3)
	old_result := simpson38(f, a, b, n)

	for n < MAX_ITERATIONS {
		// Double the intervals, maintains the multiple of 3.
		n *= 2
		new_result := simpson38(f, a, b, n)

		if math.abs(new_result - old_result) < epsilon {
			return new_result, n
		}

		old_result = new_result
	}

	log.warnf("reached maximum number of intervals (%d) without achieving desired accuracy", n)
	return old_result, n
}


adaptive2_simpson38 :: proc(
	f: Integrand,
	a: f64,
	b: f64,
	epsilon: f64 = 1e-6,
) -> (
	result: f64,
	final_m: uint,
	final_k: uint,
) {
	MAX_APPLICATIONS :: 10_000_000

	s: uint = 4 // for Simpson's 3/8 rule, the simple formula uses 4 points (s = 4)
	m: uint = 1 // initial number of formula applications
	k: uint = (s - 1) * m + 1 // number of nodes: k = (s-1)*m + 1
	n: uint = k - 1 // number of sub-intervals

	old_result := simpson38(f, a, b, n)

	for m < MAX_APPLICATIONS {
		m *= 2
		k = (s - 1) * m + 1
		n = k - 1

		new_result := simpson38(f, a, b, n)

		if math.abs(new_result - old_result) < epsilon {
			return new_result, m, k
		}

		old_result = new_result
	}

	log.warnf("reached maximum number of applications (%d) without achieving desired precision", n)
	return old_result, m, k
}
