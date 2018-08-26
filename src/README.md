****************************************
* KEPLERMATIK GRAPHICS ROUTINES 

These routines take the BMP data loaded at $4000 on the main page and copy it to $2000 on the main and auxpages in the very specific way required by DHGR.                                                       

In general, the first LDGFX sets up the required soft switches and initializes the pointers to both BMP (BMPSTART) and video RAM (GFXPTR).  It also initializes the end-of-row pointer (COLNUM).

The code then begins performing whatwe affectionately call "the pixel pokey" where we bang bits off the end of the bitmap byte pointed to by BMPPTR into the carry flag, using this flag as temporary storage for the pixel before banging it into thebyte in video RAM that's pointed to by GFXPTR.  This also has the handy effect of reversing the order of the bits which is required by the way that video RAM is structured.                                           
While the pixel pokey is going on, we keep track of two counters with the X and Y registers.  The X countsdown from 7 to 0 and tracks bits of the current BMP byte.  The Y counts down from 6 to 0 and tracks the 7 bits of the video RAM byte.  When these counters each hit zero, which implies we finished a byte, other stuff happens.                       
When the BMP counter (X) hits zero, we check to see if we're at the end of the BMP row.  If not, we just increment the BMP pointer, reset X and get back to the pixel pokey.  If we are at the end of the row, things get interesting.

Essentially, there is non-intuitive but regular structure to the DHGR memory map.  First, rows are set up in 8 row blocks where the rows are $0400 away from one another.  In our implementation, this puts row 0 at  $2000, row 1 at $2400, and so on.

These
