#include "project.h"
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
//Alex Groszewski and Victor Arias
/*************************************************************************
Strategy - We implemented Parallel Pattern Fault Simulation (PPFS).  In our
implementation, we simulate 16 patterns simultaneously. First, we simulate the 
first 16 patterns and find the FF response and store it.  Then for those 
16 patterns we iterate through the fault list and determine if any one of those
16 patterns allow the given fault to get propogated the teh POs and, if so, 
we remove the fault from the undetected_fault_list.  We then move on to the next
16 patterns and repeat.  We take extra care if the "chunk" of patterns we are dealing
with is ever <16 , and as you will be able to see we do this by shifting in 0s 
in order to allow these patterns to be compatible with the others we have determined.

Justification - We chose to do parallel pattern fault simulation because 
we initially ran a test where we timed both the slow and the fast simulator
and we noticed that the fast simulator on average was ~16x faster than the 
slow simulator.  We figured that we would be able to achieve similar 
performance if we were able to simulate 16 patterns at a time.  Also, we 
noticed that the slow version was simulating 1 "bit" (actually 2 bits) at
a time even though it was using an integer data structure (on Daisy, this
is 4 bytes or 32 bits).  We decided to convert our gate structure to use
unsigned ints (so we would avoid problems with shifting numbers with 1 
in the MSB place). and packed 16 patterns into this structure:
(32bits/(2bits/pattern)=16 patterns in parallel).We got a little less than
16x speedup with this method, which makes sense because there was still
some work that needed to be done serially, like forming parallel patterns.

Advantages - The advatage of this method is that it is relatively simple 
and easy to implement.  The way tthat the simulation is run is very similar
to the way serial pattern fault simulation is done.It also gets very good 
performance which is comparable to the fast case.
*************************************************************************/

/*************************************************************************

Function:  three_val_transition_fault_simulate

Purpose:  This function performs transition fault simulation on 3-valued
          input patterns.

pat.out[][] is filled with the fault-free output patterns corresponding to
the input patterns in pat.in[][].

Return:  List of faults that remain undetected.

*************************************************************************/

/* Macro Definitions */
#define high_bit(val) (val & 0xAAAAAAAA)

#define low_bit(val) (val & 0x55555555)


#define compute_AND(result,val1,val2) result = high_bit(((high_bit(val1)) & ~(high_bit(val2)) & ~(low_bit(val1)<<1) & (low_bit(val2)<<1))|(~(high_bit(val1)) & (high_bit(val2)) & (low_bit(val1)<<1) & ~(low_bit(val2)<<1))|((high_bit(val1))&(high_bit(val2)))) | low_bit(val1)&low_bit(val2)


#define compute_OR(result,val1,val2) result = high_bit(((high_bit(val1)) & ~(high_bit(val2)) & ~(low_bit(val1)<<1) & ~(low_bit(val2)<<1))|(~(high_bit(val1)) & (high_bit(val2)) & ~(low_bit(val1)<<1) & ~(low_bit(val2)<<1))|((high_bit(val1))&(high_bit(val2)))) | (low_bit(val1)|low_bit(val2))


#define compute_INV(result,val1) result = (high_bit(val1)) | low_bit(~(high_bit(val1)>>1)&~(low_bit(val1)))

#define compute_NAND(result,val1,val2)   result = high_bit((((high_bit(val1)) & !(low_bit(val1)<<1) & !(high_bit(val2)) & (low_bit(val2)<<1)) + (!(high_bit(val1)) & (low_bit(val1)<<1) & (high_bit(val2)) & !(low_bit(val2)<<1)) + ((high_bit(val1)) & !(low_bit(val1)<<1) & (high_bit(val2)) & !(low_bit(val2)<<1)))) | low_bit(!((low_bit(val1))&(low_bit(val2)))&!(((((high_bit(val1)>>1) & !(low_bit(val1)) & !(high_bit(val2)>>1) & (low_bit(val2))) + (!(high_bit(val1)>>1) & (low_bit(val1)) & (high_bit(val2)>>1) & !(low_bit(val2))) + ((high_bit(val1)>>1) & !(low_bit(val1)) & (high_bit(val2)>>1) & !(low_bit(val2)))))));

#define compute_NOR(result,val1,val2)    result = high_bit((((high_bit(val1)) & !(low_bit(val1)<<1) & !(high_bit(val2)) & !(low_bit(val2)<<1)) + (!(high_bit(val1)) & !(low_bit(val1)<<1) & (high_bit(val2)) & !(low_bit(val2)<<1)) + ((high_bit(val1)) & !(low_bit(val1)<<1) & (high_bit(val2)) & !(low_bit(val2)<<1)))) | low_bit(!((low_bit(val1))|(low_bit(val2)))&!(((((high_bit(val1)>>1) & !(low_bit(val1)) & !(high_bit(val2)>>1) & !(low_bit(val2))) + (!(high_bit(val1)>>1) & !(low_bit(val1)) & (high_bit(val2)>>1) & !(low_bit(val2))) + ((high_bit(val1)>>1) & !(low_bit(val1)) & (high_bit(val2)>>1) & !(low_bit(val2)))))));


#define evaluate(gate) \
  { \
    switch( gate.type ) { \
    case PI: \
      break; \
    case PO: \
    case BUF: \
      gate.out_val = gate.in_val[0]; \
      break; \
    case PO_GND: \
      gate.out_val = LOGIC_0; \
      break; \
    case PO_VCC: \
      gate.out_val = LOGIC_1; \
      break; \
    case INV: \
      compute_INV(gate.out_val,gate.in_val[0]); \
      break; \
    case AND: \
      compute_AND(gate.out_val,gate.in_val[0],gate.in_val[1]); \
      break; \
    case NAND: \
      compute_AND(gate.out_val,gate.in_val[0],gate.in_val[1]); \
      compute_INV(gate.out_val,gate.out_val); \
      break; \
    case OR: \
      compute_OR(gate.out_val,gate.in_val[0],gate.in_val[1]); \
      break; \
    case NOR: \
      compute_OR(gate.out_val,gate.in_val[0],gate.in_val[1]); \
      compute_INV(gate.out_val,gate.out_val); \
      break; \
    default: \
      assert(0); \
    } \
  }



fault_list_t *three_val_fault_simulate(ckt,pat,undetected_flist)
     circuit_t *ckt;
     pattern_t *pat;
     fault_list_t *undetected_flist;
{

  /* put your code here */
  int p;
  int i;
  int j;
  int k;
  int l;
  int q;
  int test;
  unsigned int parallel_pat;
  int pat_len_ctr;
  int pat_len_dummy;
  int pat_seg;

  fault_list_t *fptr, *prev_fptr;
  int detected_flag;

  int input_changed_flag = FALSE;
  unsigned int input_changed_dummy;
  int input_changed_gatenum;

  unsigned int golden_pattern;

  /*************************/
  /* fault-free simulation */
  /*************************/
  /*loop through all patterns*/
  pat_len_dummy = pat->len;
  parallel_pat = 0x0;
  pat_len_ctr=0;
  pat_seg=1;


  while(pat_len_dummy>0)
    {
      //printf("pat length dummy: %d\n",pat_len_dummy);
      for(i=0;i<ckt->npi;i++) // for each PI
        {
          /*form parallel input pattern when chunk >= 16 patterns*/
          if(pat_len_dummy>=16)
            {
              //printf("pat length dummy: %d\n",pat_len_dummy);


              for(p=pat_len_ctr;p<(pat_len_ctr+16);p++)
                {
                  parallel_pat = parallel_pat << 2;
                  parallel_pat |= pat->in[p][i];
                }
            }
          /*When num patterns < 16, pad extra with 0s*/
          else 
            {
              //printf("alex pat length dummy: %d\n",pat_len_dummy);
              //printf("alex pat len ctr: %d\n",pat_len_ctr);
              //printf("alex p+pat len ctr: %d\n",(p+pat_len_ctr));
             
              for(p=pat_len_ctr;p<(pat->len);p++)
                {
                  //printf("PI %d seg %d - p: %d -> %d\n",i,pat_seg,p,pat->in[p][i]);
                  parallel_pat = parallel_pat << 2;
                  parallel_pat |= pat->in[p][i];
                }

              for(p=0;p<(16-pat_len_dummy);p++)
                {
                  parallel_pat = parallel_pat << 2;
                }

            }
          //printf("parallel pat for PI %d in segment %d: %04x\n",i,pat_seg,parallel_pat);
          //set PIs with parallel pattern
          ckt->gate[ckt->pi[i]].out_val = parallel_pat;  
          //printf("parallel pat for PI %d in segment %d: %04x\n",);

        } // end FOR ALL PIs

      //printf("parallel pat for PI %d in segment %d: %08x\n",i,pat_seg,parallel_pat);

      /* evaluate all gates */
      for (j = 0; j < ckt->ngates; j++) //FOR ALL GATES
        {
        /* get gate input values */
        switch ( ckt->gate[j].type ) 
          {
          /* gates with no input terminal */
          case PI:
          case PO_GND:
          case PO_VCC:
            break;
          /* gates with one input terminal */
          case INV:
          case BUF:
          case PO:
            ckt->gate[j].in_val[0] = ckt->gate[ckt->gate[j].fanin[0]].out_val;
            break;
          /* gates with two input terminals */
          case AND:
          case NAND:
          case OR:
          case NOR:
            ckt->gate[j].in_val[0] = ckt->gate[ckt->gate[j].fanin[0]].out_val;
            ckt->gate[j].in_val[1] = ckt->gate[ckt->gate[j].fanin[1]].out_val;
            break;
          default:
            assert(0);
          }
        evaluate(ckt->gate[j]);

        ///printf("ckt gate (%d) (%d) inval 0: %04x\n",j,ckt->gate[j].type,ckt->gate[j].in_val[0]);
        ///printf("ckt gate (%d) (%d) inval 1: %04x\n",j,ckt->gate[j].type,ckt->gate[j].in_val[1]);
        ///printf("ckt gate (%d) (%d) outval : %04x\n",j,ckt->gate[j].type,ckt->gate[j].out_val);

        
        }
      unsigned int pat_out;
      //set primary outputs
      for(k=0;k<ckt->npo;k++)
        {
          pat_out = ckt->gate[ckt->po[k]].out_val;
          //printf("PO gate num : %d\n",ckt->po[k]);

          if(pat_len_dummy>=16)
            {
              //printf("Shouldnt be here for AND...\n");
              for(l=(pat_len_ctr+16-1);l>=pat_len_ctr;l--)
                {
                  //printf("%d\n",l);
                  pat->out[l][k] = pat_out&0x3;
                  pat_out = pat_out >> 2;
                }
            }
          else
            {
              for(l=0;l<(16-pat_len_dummy);l++) //scan out remainder patterns
                {
                  pat_out = pat_out >> 2;
                  //printf("nicky\n");
                }
              for(l=((pat->len)-1);l>=pat_len_ctr;l--)
                {
                  pat->out[l][k] = pat_out&0x3;
                  pat_out = pat_out >> 2;
                }
            }
          //printf("pat for PO[%d] in seg%d: %04x\n",k,pat_seg,ckt->gate[ckt->po[k]].out_val);

        }



      /********************/
      /* fault simulation */
      /********************/
      prev_fptr = (fault_list_t *)NULL;
      for (fptr=undetected_flist; fptr != (fault_list_t *)NULL ; fptr=fptr->next)    
        {

          //DEBUG STUFF
          //printf("\n");
          //if(fptr->input_index >=0)
          //  {
          //    printf("Gate %d input %d SA%d:\n",fptr->gate_index,fptr->input_index,fptr->type);
          //  }
          //else
          //  {
          //    printf("Gate %d output SA%d:\n",fptr->gate_index,fptr->type);
          //  }

          parallel_pat =0;

          //initialize PI gates with values from pat->in
          for(i=0;i<ckt->npi;i++) // for each PI
            {
              /*form parallel input pattern when chunk >= 16 patterns*/
              if(pat_len_dummy>=16)
                {
                  //printf("pat length dummy: %d\n",pat_len_dummy);
                  
                  
                  for(p=pat_len_ctr;p<(pat_len_ctr+16);p++)
                    {
                      parallel_pat = parallel_pat << 2;
                      parallel_pat |= pat->in[p][i];
                    }
                }
              /*When num patterns < 16, pad extra with 0s*/
              else 
                {
                  //printf("alex pat length dummy: %d\n",pat_len_dummy);
                  //printf("alex pat len ctr: %d\n",pat_len_ctr);
                  //printf("alex p+pat len ctr: %d\n",(p+pat_len_ctr));
             
                  for(p=pat_len_ctr;p<(pat->len);p++)
                    {
                      //printf("PI %d seg %d - p: %d -> %d\n",i,pat_seg,p,pat->in[p][i]);
                      parallel_pat = parallel_pat << 2;
                      parallel_pat |= pat->in[p][i];
                    }

                  for(p=0;p<(16-pat_len_dummy);p++)
                    {
                      parallel_pat = parallel_pat << 2;
                    }

                }
              //printf("parallel pat for PI %d in segment %d: %04x\n",i,pat_seg,parallel_pat);
              //set PIs with parallel pattern
              ckt->gate[ckt->pi[i]].out_val = parallel_pat;  
              //printf("parallel pat for PI %d in segment %d: %04x\n",);

            } // end FOR ALL PIs


          detected_flag = FALSE;
          for (j = 0; j < ckt->ngates; j++) //FOR ALL GATES
            {
              /* get gate input values */
              switch ( ckt->gate[j].type ) 
                {
                  /* gates with no input terminal */
                  case PI:
                  case PO_GND:
                  case PO_VCC:
                  break;
                  /* gates with one input terminal */
                  case INV:
                  case BUF:
                  case PO:
                  ckt->gate[j].in_val[0] = ckt->gate[ckt->gate[j].fanin[0]].out_val;
                  break;
                  /* gates with two input terminals */
                  case AND:
                  case NAND:
                  case OR:
                  case NOR:
                  ckt->gate[j].in_val[0] = ckt->gate[ckt->gate[j].fanin[0]].out_val;
                  ckt->gate[j].in_val[1] = ckt->gate[ckt->gate[j].fanin[1]].out_val;
                  break;
                  default:
                  assert(0);
                }

              //check if faulty gate
              if( j == fptr->gate_index)
                {
                  if( fptr->input_index >= 0) //input fault
                    {
                      if(fptr->type == S_A_0)
                        {
                          ckt->gate[j].in_val[fptr->input_index] = ZERO_MASK;
                        }
                      else
                        {
                          ckt->gate[j].in_val[fptr->input_index] = ONE_MASK;
                        }
                      evaluate(ckt->gate[j]);
                    }
                  else // fault at output
                    {     
                      if(fptr->type == S_A_0)
                        {
                          ckt->gate[j].out_val = ZERO_MASK;
                        }
                      else
                        {
                          ckt->gate[j].out_val = ONE_MASK;
                        }
                    }
                }
              else //not faulty
                {
                  evaluate(ckt->gate[j]);
                }

              ///printf("(F} ckt gate (%d) (%d) inval 0: %04x\n",j,ckt->gate[j].type,ckt->gate[j].in_val[0]);
              ///printf("(F} ckt gate (%d) (%d) inval 1: %04x\n",j,ckt->gate[j].type,ckt->gate[j].in_val[1]);
              ///printf("(F} ckt gate (%d) (%d) outval : %04x\n",j,ckt->gate[j].type,ckt->gate[j].out_val);

            } //end FOR ALL GATES


          //


          unsigned int pat_out_fault=0;
          //unsigned int faulty_output=0;
          //set primary outputs
          for(k=0;k<ckt->npo&&!detected_flag;k++)
            {
              pat_out_fault = ckt->gate[ckt->po[k]].out_val;
              //printf("PO gate num : %d\n",ckt->po[k]);
          
              if(pat_len_dummy>=16)
                {
                  //printf("Shouldnt be here for AND...\n");
                  for(l=(pat_len_ctr+16-1);l>=pat_len_ctr&&!detected_flag;l--)
                    {
                      //printf("%d\n",l);
                      ///printf("pat out[%d][%d]: %01x\n",l,k,pat->out[l][k]);
                      ///printf("faulty         : %01x\n",pat_out_fault&0x3);
                      //if((pat->out[l][k]) != (pat_out_fault&0x3))
                      if(((pat->out[l][k]==1) && ((pat_out_fault&0x3)==0))||((pat->out[l][k]==0) && ((pat_out_fault&0x3)==1)))

                        {
                          detected_flag = TRUE;
                        }                     
                      pat_out_fault = pat_out_fault >> 2;
                    }
                }
              else
                {
                  for(l=0;l<(16-pat_len_dummy);l++) //scan out remainder patterns
                    {
                      pat_out_fault = pat_out_fault >> 2;
                      //printf("nicky\n");
                    }
                  for(l=((pat->len)-1);l>=pat_len_ctr&&!detected_flag;l--)
                    {
                      //faulty_output = pat_out_fault&0x3;
                      ///printf("pat out[%d][%d]: %01x\n",l,k,pat->out[l][k]);
                      ///printf("faulty         : %01x\n",pat_out_fault&0x3);
                      if(((pat->out[l][k]==1) && ((pat_out_fault&0x3)==0))||((pat->out[l][k]==0) && ((pat_out_fault&0x3)==1)))
                        {
                          detected_flag = TRUE;
                        }
                      ///signed int my_fault = pat_out_fault&0x3;
                      ///((pat->out[l][k]==0)&&(my_fault==1))
                      ///{
                      ///  printf("ALEX fault: %04x\n",pat->out[l][k]);
                      ///  printf("ALEX fault: %04x\n",my_fault);
                      ///  detected_flag = TRUE;
                      ///}
                      ///f((pat->out[l][k]==1)&&(my_fault==0))
                      ///{
                      ///  printf("ALEX fault: %04x\n",pat->out[l][k]);
                      ///  printf("ALEX fault: %04x\n",my_fault);
                      ///
                      ///  detected_flag = TRUE;
                      ///}                     

                      pat_out_fault = pat_out_fault >> 2;
                    }
                }
              //printf("NEW pattern in seg%d: %08x\n",pat_seg,faulty_output);
              //printf("%08x\n",pat->out[0][0]);
          
            }


          if ( detected_flag ) {
            /* remove fault from undetected fault list */
            if ( prev_fptr == (fault_list_t *)NULL ) {
              /* if first fault in fault list, advance head of list pointer */
              undetected_flist = fptr->next;
            }
            else { /* if not first fault in fault list, then remove link */
              prev_fptr->next = fptr->next;
            }
          }
          else { /* fault remains undetected, keep on list */
            prev_fptr = fptr;
          }

        } //end FOR ALL FAULTS




      //printf("faults remaining after segment %d: \n",pat_seg);
      ///for (fptr=undetected_flist; fptr != (fault_list_t *)NULL; fptr=fptr->next)
      ///  {
      ///    if(fptr->input_index >=0)
      ///      {
      ///        printf("Gate %d input %d SA%d:\n",fptr->gate_index,fptr->input_index,fptr->type);
      ///      }
      ///    else
      ///      {
      ///        printf("Gate %d output SA%d:\n",fptr->gate_index,fptr->type);
      ///      }
      ///
      ///  }
      
      pat_len_dummy -= 16;
      pat_len_ctr += 16;
      pat_seg++;
     

    } //end WHILE PAT_LEN_DUMMY > 0

  //unsigned int in0 = ckt->gate[2].in_val[0];
  //unsigned int in1 = ckt->gate[2].in_val[0];

  //printf("%04x\n",in0);
  //printf("%04x\n",high_bit(in0));
  //printf("%04x\n",~(high_bit(in0)));
  //printf("%04x\n",low_bit(in0));
  //
  //printf("%04x\n",in1);




  return(undetected_flist);
}
