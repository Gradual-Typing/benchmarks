(* taken from ... *)
(* ARRAY1 -- One of the Kernighan and Van Wyk benchmarks. *)
(* 9/27/2017 added types to support typed-racket by Andre Kuhlenschmidt *)
(* 9/28/2017 ported to ocaml *)
(* 3/25/2019 adding type annotations *)

let create_x (n : int) : (int array) =
  let result = Array.make n 0 in
  for i = 0 to n - 1 do
    result.(i) <- i;
  done;
  result
  
let create_y (x : int array) : (int array) =
  let n = Array.length x in
  let result = Array.make n 0 in
  for i = n - 1 downto 0 do
    result.(i) <- x.(i)
  done;
  result

let my_try (n : int) : int = Array.length (create_y (create_x n))

let rec go (m : int) (n : int) (r : int) : int =
  if m > 0 then
    go (m - 1) n (my_try n)
  else r

let run_benchmark () =
  let input1 = int_of_string(input_line stdin) in
  let input2 = int_of_string(input_line stdin) in
  Printf.printf "%d\n" (go input1 input2 0)

let () = Time.time run_benchmark ()
