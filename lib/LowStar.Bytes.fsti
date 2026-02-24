(*
   Copyright 2008-2017 Microsoft Research

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*)
(** LowStar-dependent operations on bytes (buffers, stack allocation).
    Extends FStar.Bytes with operations that depend on LowStar.Buffer and FStar.HyperStack.ST. *)
module LowStar.Bytes

include FStar.Bytes

module B = LowStar.Buffer
module M = LowStar.Modifies

open FStar.HyperStack.ST

type lbuffer (l:UInt32.t) = b:B.buffer UInt8.t {B.length b == UInt32.v l}

val of_buffer (l:UInt32.t) (#p #q:_) (buf:B.mbuffer UInt8.t p q{B.length buf == UInt32.v l})
  : Stack (b:bytes{length b = UInt32.v l})
  (requires fun h0 ->
    B.live h0 buf)
  (ensures  fun h0 b h1 ->
    B.(modifies loc_none h0 h1) /\
    b = hide (B.as_seq h0 buf))

val store_bytes: src:bytes { length src <> 0 } ->
  dst:lbuffer (len src) ->
  Stack unit
    (requires (fun h0 -> B.live h0 dst))
    (ensures  (fun h0 r h1 ->
      M.(modifies (loc_buffer dst) h0 h1) /\
      Seq.equal (reveal src) (B.as_seq h1 dst)))

(* JP: let's not add from_bytes here because we want to leave it up to the
caller to allocate on the stack or on the heap *)
