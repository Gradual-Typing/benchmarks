(* 3/25/2019 adding type annotations *)

type stream = Mk_stream of int * (unit -> stream)

let stream_first (st : stream) : int =
  match st with
    Mk_stream (f,r) -> f

let stream_rest (st : stream) : stream =
  match st with
    Mk_stream (f,r) -> r ()

let rec stream_get (st : stream) (n : int) : int =
  if n == 0
  then stream_first st
  else stream_get (stream_rest st) (n - 1)

let rec count_from (n : int) : stream =
  Mk_stream(n, (fun u -> count_from (n + 1)))

let rec sift (n : int) (st : stream) : stream =
  let hd = stream_first st in
  if hd mod n == 0
  then sift n (stream_rest st) 
  else Mk_stream (hd, fun () -> sift n (stream_rest st))

let rec sieve (st : stream) : stream =
   let hd = stream_first st in
   Mk_stream (hd, (fun () -> sieve (sift hd (stream_rest st))))


let primes : stream = sieve (count_from 2)

let run_benchmark () =
  let n_1 = read_int () in
  Printf.printf "%d\n" (stream_get primes n_1)

let () = Time.time run_benchmark ()
