import Foundation


struct PlaceNotation {
  let stage: Stage
  private let changes: [RawRow]
  private let rows: [RawRow]
}


/*
 
 Sketching out interpretation of places
 
 multiplying by 3;5
 bells that make:      0 0 F 0 0
 bells that move up:   F 0 0 F 0
 bells that move down: 0 F 0 0 F
 
 multiplying by 14;4
 bells that make:       F 0 0 F
 bells that move up:    0 F 0 0
 bells that move down:  0 0 F 0
 
 multiplying by 14;6
 bells that make:       F 0 0 F 0 0
 bells that move up:    0 F 0 0 F 0
 bells that move down:  0 0 F 0 0 F
 
 I do think the following procedure works:
 - start with transp = (F00...,0F000...)
 - if transp & places, shift transp >> 4, loop; else:
 - up |= transp.0, down |= transp.1
 - transp >> 8
 
 We'd like to go directly to the row, so instead:
 - row |= (row & transp.0) >> 4
 - row |= (row & transp.1) << 4
 
 
 */
