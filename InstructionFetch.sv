module IF(clk, reset, ins_cache, pc, read_enable);

    input logic clk;
    input logic reset;
           
    input logic[0:31] ins_cache[0:15];  // Instruction line buffer , stores 64B instruction

    
    logic[0:31] instr_d[0:1];           // 2 instruction sent to DECODE stage
    logic stall;                        // incase of stall Instruction fetch 
                                        //should stop fetching new instruction

    output logic read_enable;           // Used to signal that IF is ready to read next set of 64B instruction

    output logic[7:0]   pc;
    
    logic[7:0]	pc_wb;                  // pc_wb access as reset PC signal for IF to start new instr read position
    logic[7:0] pc_check;                // used for checkpointing, to adjust the pc while reading from ins_cache


    Decode decode(clk, reset, instr_d, pc, pc_wb, stall);


    always_comb begin : pc_counter
            if(reset == 1) begin
                pc_check = 0;
                read_enable =1;
            end
            else begin
                // read_enable =0;
                if(pc_wb-pc_check > 15) begin
                    pc_check = pc_check + pc_wb;
                    read_enable =1;
                    $display($time,"IF: Prefetch pc_check %d pc_wb %d ", pc_check, pc_wb);
                end
                else if(pc-pc_check == 16) begin
                    pc_check = pc+pc_check; // Need to handle boundary instruction
                    read_enable =1;
                    $display($time,"IF: Prefetch  pc_check %d pc %d ", pc_check, pc);
                end
                else begin
                    read_enable = 0;
                end
            end

            // if( (pc+2)%16 == 0) begin 
            //     // We fetch 64B instruction from LS [ as per the SPE orgnisation ]
            //     // Once we reach 16 in count we fetch new set of 16 instruction
            //     //  need to handle case when have branch/ stall in some intermedial level
            //     // we will have to fetch old set of instruction from memory 
            //     // this can be done using pc_wb 
                
            //     read_enable =1;
            // end
             
    end

    always_ff @(posedge clk) begin : fetch_instruction
        
        $display($time," IF: stall %d pc %d pc_wb %d  read_enable %d ",stall, pc, pc_wb, read_enable);

        if(reset == 1 ) begin
            pc<=0;
            
            instr_d[0]<=32'h0000;
            instr_d[1]<=32'h0000;
            
        end
        else begin
            
         
            // Use of stall is to stop IF fetching new instruction 
            // This can be used in case of dual issue conflicts where decode
            // inserts no-op instruction 
            // we use pc_wb to continue fetch new stream of instruction then onwards
            
            if( stall==0 ) begin
                // stall<=0;
                instr_d[0]<=ins_cache[pc-pc_check];
                instr_d[1]<=ins_cache[pc+1-pc_check];
                $display($time," IF: ins %b ins %b pc %d pc_wb %d read_enable %d ",ins_cache[pc-pc_check], ins_cache[pc+1],pc,pc_wb, read_enable);
                $display($time," IF: ins %h ins %h pc %d pc_wb %d read_enable %d ",ins_cache[pc-pc_check], ins_cache[pc+1],pc,pc_wb, read_enable);


                $display($time," IF: ins %b ins %b pc %d pc_wb %d read_enable %d ",instr_d[0], instr_d[1],pc,pc_wb, read_enable);
                $display($time," IF: ins %h ins %h pc %d pc_wb %d read_enable %d ",instr_d[0], instr_d[1],pc,pc_wb, read_enable);

                pc <= pc+2;

                
            end
            else begin
                
                pc <= pc_wb; // Incase of stall we rely  on pc_wb to start fetch of new instruction
                $display($time,"IF: pc update to pc_wb %d pc %d" ,pc_wb, pc);
                instr_d[0]<= 32'h0000;//ins_cache[pc_wb-pc_check];
                instr_d[1]<= 32'h0000;//ins_cache[pc_wb+1-pc_check];
                
                // $display($time," IF: reading in using pc_wb");
                // $display($time," IF: ins %b ins %b pc %d pc_wb %d read_enable %d ",ins_cache[pc_wb], ins_cache[pc_wb+1],pc,pc_wb, read_enable);
                // $display($time," IF: ins %h ins %h pc %d pc_wb %d read_enable %d ",ins_cache[pc_wb], ins_cache[pc_wb+1],pc,pc_wb, read_enable);

            end
        end
    end

endmodule