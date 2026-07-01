//
// (c) Technion IIT, The Faculty of Electrical and Computer Engineering, 2025
//
//
//  PRELIMINARY VERSION  -  06 April 2025
//


module JukeBox1

    (
    // Declare wires and regs :
 
 input logic [3:0] melodySelect ,     // selector of one melody  
 input logic [4:0] noteIndex,         // serial number of current note. ( maximum 31 ). noteIndex determines freqIndex and note_length, via JueBox
 
 output logic [3:0] tone,        // index to toneDecoder
 output logic [3:0] note_length,      // length of notes, in beats
 output logic silenceOutN ) ;         //  a silence note: disable sound
 

 localparam MaxMelodyLength = 6'h32;  // maximum melody length, in notes. 
	

// ************** frequencies: *************************************************************************************************
    typedef enum logic [3:0] {do_, doD, re, reD, mi, fa, faD, sol, solD, la, laD, si, do_H, doDH, re_H, silence } musicNote ;//*
//              Hex value:     0    1    2   3   4    5   6    7     8    9   A   B    C      D    E      F                  //*
// *****************************************************************************************************************************
      
   // type of frequency is musicNote   (enum)  
   // Frequency index is 0....15   
   // length is in beats ( 1 to 15 )
   // length = 0 means end of melody		

musicNote frq[(MaxMelodyLength-1'b1):0]  ;     // frq is the array of frequency indices of the melody. it includes up to 32 notes.  
logic [3:0] len[(MaxMelodyLength-1'b1):0] ;   // len is the array of note lengths , in terms of beats. it includes up to 32 notes.		

assign silenceOutN = !( tone == silence ) ; // disable sound if note is "silence"	 
	 
	 
	 
always_comb begin	 
    frq = '{default: 0};
	 len = '{default: 0}; 
  case (melodySelect)  
      0:   begin
	
			//********************************************************************** 
			// Sheet Music of song:  YONATAN HAKATAN  ( up to 32 notes )          *
			//**********************************************************************

				 frq[0] = sol ;           len[0] = 2 ;    // YO  ( e.g.: sol, length = 2 beats )
				 frq[1] =  mi ;           len[1] = 2 ;    // NA
				 frq[2] =  mi ;           len[2] = 4 ;    // TAN ( e.g.: mi, length = 6 beats)

				 frq[3] =  fa ;           len[3] = 2 ;    // Ha   
				 frq[4] =  re ;           len[4] = 2 ;    // KA
				 frq[5] =  re ;           len[5] = 4 ;    // TAN

				 
				 frq[6] =  do_ ;           len[6] = 2 ;   // RATZ
				 frq[7] =  re  ;           len[7] = 2 ;   // BA
				 frq[8] =  mi  ;           len[8] = 2 ;   // BO
				 frq[9] =  fa  ;           len[9] = 2 ;   // KER
				 frq[10]=  sol ;           len[10]= 2 ;   // EL
				 frq[11]=  sol ;           len[11]= 2 ;   // HA
				 frq[12]=  sol ;           len[12]= 4 ;   // GAN
				 
				 frq[13] = sol ;           len[13] = 2 ;   // HU  
				 frq[14] =  mi ;           len[14] = 2 ;   // TI
				 frq[15] =  mi ;           len[15] = 4 ;   // PES 

				 frq[16] =  fa ;           len[16] = 2 ;   // AL   
				 frq[17] =  re ;           len[17] = 2 ;   // HA
				 frq[18] =  re ;           len[18] = 4 ;   // ETZ
				 
				 frq[19] =  do_;           len[19] = 2 ;   // EF   
				 frq[20] =  mi ;           len[20] = 2 ;   // RO
				 frq[21] =  sol;           len[21] = 2 ;   // CHIM   
	    		
				 frq[22] =  sol;           len[22] = 2 ;   // CHI
				 frq[23] =  do_;           len[23] = 7 ;   // PES   			 
				 frq[24] = do_ ;           len[24] = 0 ;    // length = 0 means end of melody
	
	
       end // case 0 

      1:   begin
			//************************************************************************************************** 
			// In-Game Music - Classic 1967 Spider-Man Theme Song
			//**************************************************************************************************
				  // "Spider-man, Spider-man"
				  frq[0]  =  re   ;      len[0]  = 2  ;   
				  frq[1]  =  fa   ;      len[1]  = 2  ;   
				  frq[2]  =  la   ;      len[2]  = 4  ;   
				  frq[3]  =  silence;    len[3]  = 2  ;   
				  frq[4]  =  re   ;      len[4]  = 2  ;   
				  frq[5]  =  fa   ;      len[5]  = 2  ;   
				  frq[6]  =  la   ;      len[6]  = 4  ;   
				  frq[7]  =  silence;    len[7]  = 2  ;   
				  
				  // "Does whatever a spider can"
				  frq[8]  =  la   ;      len[8]  = 2  ;   
				  frq[9]  =  la   ;      len[9]  = 2  ;   
				  frq[10] =  sol  ;      len[10] = 2  ;   
				  frq[11] =  sol  ;      len[11] = 2  ;   
				  frq[12] =  fa   ;      len[12] = 2  ;   
				  frq[13] =  mi   ;      len[13] = 2  ;   
				  frq[14] =  re   ;      len[14] = 4  ;   
				  frq[15] =  silence;    len[15] = 2  ;   
				  
				  // "Spins a web, any size"
				  frq[16] =  sol  ;      len[16] = 2  ;   
				  frq[17] =  laD  ;      len[17] = 2  ;   
				  frq[18] =  re_H ;      len[18] = 4  ;   
				  frq[19] =  silence;    len[19] = 2  ;   
				  frq[20] =  sol  ;      len[20] = 2  ;   
				  frq[21] =  laD  ;      len[21] = 2  ;   
				  frq[22] =  re_H ;      len[22] = 4  ;   
				  frq[23] =  silence;    len[23] = 2  ;   
				  
				  // "Catches thieves just like flies"
				  frq[24] =  re_H ;      len[24] = 2  ;   
				  frq[25] =  re_H ;      len[25] = 2  ;   
				  frq[26] =  do_H ;      len[26] = 2  ;   
				  frq[27] =  do_H ;      len[27] = 2  ;   
				  frq[28] =  laD  ;      len[28] = 2  ;   
				  frq[29] =  la   ;      len[29] = 2  ;   
				  frq[30] =  sol  ;      len[30] = 4  ;   
				  frq[31] =  silence;    len[31] = 2  ;   
				  
				  // "Look out!"
				  frq[32] =  fa   ;      len[32] = 4  ;   
				  frq[33] =  la   ;      len[33] = 4  ;   
				  frq[34] =  silence;    len[34] = 2  ;   
				  
				  // "Here comes the Spider-man!"
				  frq[35] =  re_H ;      len[35] = 2  ;   
				  frq[36] =  do_H ;      len[36] = 2  ;   
				  frq[37] =  la   ;      len[37] = 2  ;   
				  frq[38] =  sol  ;      len[38] = 2  ;   
				  frq[39] =  fa   ;      len[39] = 2  ;   
				  frq[40] =  re   ;      len[40] = 8  ;   
				  
   				  frq[41] = do_ ;        len[41] = 0 ;    // length = 0 means end of melody
				
      end // case 1
	
      2:   begin
			
			//************************************************************************************************** 
			// Sheet Music of melody:  do re mi fa sol la si do                                                *
			//**************************************************************************************************
			 
				  frq[0]  =  do_ ;      len[0]  = 2  ;   
				  frq[1]  =  re  ;      len[1]  = 2  ;   
				  frq[2]  =  mi  ;      len[2]  = 2  ;   
				  frq[3]  =  fa  ;      len[3]  = 2  ;  
				  frq[4]  =  sol ;      len[4]  = 2  ;  
				  frq[5]  =  la  ;      len[5]  = 2  ;   
				  frq[6]  =  si  ;      len[6]  = 2  ;   
				  frq[7]  =  do_H ;     len[7]  = 2  ;   
				  frq[8]  =  re_H ;     len[8]  = 6  ;   

	 			  frq[9] = do_ ;     len[9] = 0 ;    // length = 0 means end of melody
				 
      end // case 2 

      3:   begin
			
			//************************************************************************************************** 
			// Sheet Music of melody:  REVERSE ORDER OF: do re mi fa sol la si do                                                *
			//**************************************************************************************************
			 
				  frq[8]  =  do_ ;      len[8]  = 6  ;   
				  frq[7]  =  re  ;      len[7]  = 2  ;   
				  frq[6]  =  mi  ;      len[6]  = 2  ;   
				  frq[5]  =  fa  ;      len[5]  = 2  ;  
				  frq[4]  =  sol ;      len[4]  = 2  ;  
				  frq[3]  =  la  ;      len[3]  = 2  ;   
				  frq[2]  =  si  ;      len[2]  = 2  ;   
				  frq[1]  =  do_H ;     len[1]  = 2  ;   
				  frq[0]  =  re_H ;     len[0]  = 2  ;   

	 			  frq[9] = do_ ;     len[9] = 0 ;    // length = 0 means end of melody
  
      end // case 3 


      4:   begin		
			//************************************************************************************************** 
			// Store Music - Mary Had a Little Lamb
			//**************************************************************************************************			 
				  frq[0]  =  mi  ;       len[0]  = 2  ;   
				  frq[1]  =  re  ;       len[1]  = 2  ;   
				  frq[2]  =  do_ ;       len[2]  = 2  ;   
				  frq[3]  =  re  ;       len[3]  = 2  ;   
				  frq[4]  =  mi  ;       len[4]  = 2  ;   
				  frq[5]  =  mi  ;       len[5]  = 2  ;   
				  frq[6]  =  mi  ;       len[6]  = 4  ;   
				  frq[7]  =  re  ;       len[7]  = 2  ;   
				  frq[8]  =  re  ;       len[8]  = 2  ;   
				  frq[9]  =  re  ;       len[9]  = 4  ;   
				  frq[10] =  mi  ;       len[10] = 2  ;   
				  frq[11] =  sol ;       len[11] = 2  ;   
				  frq[12] =  sol ;       len[12] = 4  ;   
	 			  frq[13] =  do_ ;       len[13] = 0  ;    // length = 0 means end of melody
      end // case 4

      5:   begin		
			//************************************************************************************************** 
			// Boss Level Music - Deep, dark, Jaws-like loop
			//**************************************************************************************************			 
				  frq[0]  =  do_ ;       len[0]  = 4  ;   
				  frq[1]  =  doD ;       len[1]  = 4  ;   
				  frq[2]  =  do_ ;       len[2]  = 4  ;   
				  frq[3]  =  re  ;       len[3]  = 4  ;   
				  frq[4]  =  do_ ;       len[4]  = 2  ;   
				  frq[5]  =  doD ;       len[5]  = 2  ;   
				  frq[6]  =  re  ;       len[6]  = 2  ;   
				  frq[7]  =  reD ;       len[7]  = 4  ;   
	 			  frq[8]  =  do_ ;       len[8]  = 0  ;    // length = 0 means end of melody
      end // case 5

      6:   begin		
			//************************************************************************************************** 
			// Lobby Music - Twinkle Twinkle Little Star
			//**************************************************************************************************			 
				  frq[0]  =  do_ ;       len[0]  = 2  ;   
				  frq[1]  =  do_ ;       len[1]  = 2  ;   
				  frq[2]  =  sol ;       len[2]  = 2  ;   
				  frq[3]  =  sol ;       len[3]  = 2  ;   
				  frq[4]  =  la  ;       len[4]  = 2  ;   
				  frq[5]  =  la  ;       len[5]  = 2  ;   
				  frq[6]  =  sol ;       len[6]  = 4  ;   
				  frq[7]  =  fa  ;       len[7]  = 2  ;   
				  frq[8]  =  fa  ;       len[8]  = 2  ;   
				  frq[9]  =  mi  ;       len[9]  = 2  ;   
				  frq[10] =  mi  ;       len[10] = 2  ;   
				  frq[11] =  re  ;       len[11] = 2  ;   
				  frq[12] =  re  ;       len[12] = 2  ;   
				  frq[13] =  do_ ;       len[13] = 4  ;   
	 			  frq[14] =  do_ ;       len[14] = 0 ;    // length = 0 means end of melody
      end // case 6

      7:   begin		
			//************************************************************************************************** 
			// Grab Item SFX - Quick high pitch chime
			//**************************************************************************************************			 
				  frq[0]  =  do_H ;      len[0]  = 1  ;   
				  frq[1]  =  mi   ;      len[1]  = 1  ;   
				  frq[2]  =  sol  ;      len[2]  = 3  ;   
	 			  frq[3]  =  do_  ;      len[3]  = 0  ;    // length = 0 means end of melody
      end // case 7

      8:   begin		
			//************************************************************************************************** 
			// Explosion SFX - Fast dissonant rumble
			//**************************************************************************************************			 
				  frq[0]  =  do_ ;       len[0]  = 1  ;   
				  frq[1]  =  doD ;       len[1]  = 1  ;   
				  frq[2]  =  re  ;       len[2]  = 1  ;   
				  frq[3]  =  do_ ;       len[3]  = 1  ;   
				  frq[4]  =  reD ;       len[4]  = 1  ;   
				  frq[5]  =  doD ;       len[5]  = 1  ;   
				  frq[6]  =  do_ ;       len[6]  = 1  ;   
				  frq[7]  =  re  ;       len[7]  = 1  ;   
				  frq[8]  =  do_ ;       len[8]  = 1  ;   
				  frq[9]  =  doD ;       len[9]  = 1  ;   
	 			  frq[10] =  do_ ;       len[10] = 0 ;    // length = 0 means end of melody
      end // case 8

      9:   begin		
			//************************************************************************************************** 
			// Cha Ching SFX (Buy Item) - Very fast high notes
			//**************************************************************************************************			 
				  frq[0]  =  si   ;      len[0]  = 1  ;   
				  frq[1]  =  re_H ;      len[1]  = 1  ;   
				  frq[2]  =  si   ;      len[2]  = 1  ;   
				  frq[3]  =  re_H ;      len[3]  = 2  ;   
	 			  frq[4]  =  do_  ;      len[4]  = 0  ;    // length = 0 means end of melody
      end // case 9

      10:   begin		
			//************************************************************************************************** 
			// Door Bell SFX (Exit Store) - Bing Bong
			//**************************************************************************************************			 
				  frq[0]  =  do_H ;      len[0]  = 4  ;   
				  frq[1]  =  sol  ;      len[1]  = 6  ;   
	 			  frq[2]  =  do_  ;      len[2]  = 0  ;    // length = 0 means end of melody
      end // case 10

      11:   begin		
			//************************************************************************************************** 
			// Level Complete SFX - Triumphant jingle
			//**************************************************************************************************			 
				  frq[0]  =  sol  ;      len[0]  = 2  ;   
				  frq[1]  =  do_H ;      len[1]  = 2  ;   
				  frq[2]  =  mi   ;      len[2]  = 2  ;   
				  frq[3]  =  sol  ;      len[3]  = 4  ;   
				  frq[4]  =  do_H ;      len[4]  = 6  ;   
	 			  frq[5]  =  do_  ;      len[5]  = 0  ;    // length = 0 means end of melody
      end // case 11

      12:   begin		
			//************************************************************************************************** 
			// Game Over SFX - Sad descending tones
			//**************************************************************************************************			 
				  frq[0]  =  do_H ;      len[0]  = 4  ;   
				  frq[1]  =  la   ;      len[1]  = 4  ;   
				  frq[2]  =  fa   ;      len[2]  = 4  ;   
				  frq[3]  =  re   ;      len[3]  = 4  ;   
				  frq[4]  =  do_  ;      len[4]  = 8  ;   
	 			  frq[5]  =  do_  ;      len[5]  = 0  ;    // length = 0 means end of melody
      end // case 12

		
		default: begin
			//************************************************************************************************** 
			// Silence Track (Used to stop music)
			//**************************************************************************************************
				  frq[0]  =  silence;    len[0]  = 1  ;   
	 			  frq[1]  =  do_ ;       len[1]  = 0  ;    // length = 0 means end of melody
      end
   endcase
  end // always 
 
//***********************************************************************
//     Extract outputs of specific note from sheet music :                                                        *
//***********************************************************************

assign tone   = frq[noteIndex] ;
assign note_length = len[noteIndex] ; 

 
 
endmodule

