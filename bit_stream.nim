import streams, bitops

# TODO: endianness
# system.cpu.endian

type
  BufType = uint16

  # mainly need new object to store buffer and offset independently
  BitStream* = object
    # does this need to be exposed for setting position?
    # if not, I need an initBitStream method
    s*: Stream
    buffer: BufType
    offset: byte # only needs to be a byte as max bit size is 64


# relies on the fact that buffer == 0, if returnToStart is used this would break
# TODO:fix this
proc writeBit*(bitStream: var BitStream, bit: bool) =
  # add to buffer
  if bit:
    bitStream.buffer.setBit(bitStream.offset)


  # write buffer to stream if it is full
  if bitStream.offset >= sizeof(BufType)*8:
    bitStream.s.write(bitStream.buffer)

    bitStream.buffer = 0
    bitStream.offset = 0

  inc bitStream.offset


#new
proc readBit(bitStream: var BitStream): bool =

  if bitStream.offset >= sizeof(BufType)*8:
    bitstream.offset = 0
    # get next section
    bitStream.s.read(bitstream.buffer)
    echo "section"

  result = bitStream.buffer.testBit(bitStream.offset)

  inc bitStream.offset

  #TODO:end check?

proc atEnd(bitStream: var BitStream): bool =
  # will this leave out the last bit?
  bitStream.s.atEnd() and bitStream.offset >= sizeof(BufType)*8


proc returnToStart(bitStream: var BitStream) =
  bitStream.s.setPosition(0)
  bitStream.offset = 0
  # populate buffer, TODO: design change?
  bitStream.s.read(bitStream.buffer)


proc flush*(bitStream: var BitStream) =
  bitStream.s.write(bitStream.buffer)
  # reverse so that we can keep writing if we want to
  bitStream.s.setPosition(bitStream.s.getPosition() - sizeof(BufType))


proc flush_close*(bitStream: var BitStream) =
  bitStream.s.write(bitStream.buffer)
  bitStream.s.close()


when isMainModule:
  #from strutils import toBin

  var b: BitStream
  b.s = newStringStream()
  for _ in countup(1, 16):
    b.writeBit(true)
  b.flush()
  b.writeBit(false)
  b.writeBit(true)
  b.flush()

  #b.s.setPosition(0)
  b.returnToStart()

  #var buf: BufType
  var i = 0
  while not b.atEnd():
    inc i
    echo i, " ", b.readBit()
    # looks good
    # TODO: maybe add setEndOffset()?
    #b.s.read(buf)
    # right = lower, always breaks my brain
    #echo buf.int.toBin(sizeof(BufType)*8)
  b.flush_close()
