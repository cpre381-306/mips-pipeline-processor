-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- MIPS_Processor.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a skeleton of a MIPS_Processor  
-- implementation.

-- 01/29/2019 by H3::Design created.
-------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.MIPS_types.all;

entity MIPS_Processor is
	generic(N : integer := DATA_WIDTH);
	port(iCLK            : in std_logic;
	    iRST            : in std_logic;
	    iInstLd         : in std_logic;
	    iInstAddr       : in std_logic_vector(N-1 downto 0);
	    iInstExt        : in std_logic_vector(N-1 downto 0);
	    oALUOut         : out std_logic_vector(N-1 downto 0)); -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.

end  MIPS_Processor;


architecture structure of MIPS_Processor is

	component mem is
		generic(ADDR_WIDTH : integer;
			DATA_WIDTH : integer);
		port(
			clk          : in std_logic;
			addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
			data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
			we           : in std_logic := '1';
			q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component;

	--------------------------  COMPONENTS  --------------------------
	component PC_reg is
		generic(N : integer);
		port(
			i_CLK	: in std_logic;     -- Clock input
			i_RST	: in std_logic;     -- Reset input
			i_WE	: in std_logic;		-- Write enable
			i_D		: in std_logic_vector(N-1 downto 0);     -- Data value input
			o_Q		: out std_logic_vector(N-1 downto 0));   -- Data value output
	end component;

	component IFID_reg is
		generic(N : integer := 32);
		port(
			i_CLK       : in std_logic;	-- Clock input
			i_RST       : in std_logic;	-- Reset input
			i_WE		: in std_logic;	-- Write enable
			i_Inst		: in std_logic_vector(N-1 downto 0);	-- Full instruction
			i_PCPlus4	: in std_logic_vector(N-1 downto 0);	-- PC + 4
			o_Inst		: out std_logic_vector(N-1 downto 0);
			o_PCPlus4	: out std_logic_vector(N-1 downto 0));
	end component;
		
	component IDEX_reg is
		generic(N : integer := 32);
		port(
			i_CLK		: in std_logic;	-- Clock input
			i_RST		: in std_logic;	-- Reset input
			i_WE		: in std_logic;	-- Write enable

			i_Rs		: in std_logic_vector(DATA_SELECT-1 downto 0);	-- Instruction Rs
			i_Rt		: in std_logic_vector(DATA_SELECT-1 downto 0);	-- Instruction Rt
			i_Rd		: in std_logic_vector(DATA_SELECT-1 downto 0);	-- Instruction Rd
			i_ReadRs	: in std_logic_vector(N-1 downto 0);	-- Read Rs
			i_ReadRt	: in std_logic_vector(N-1 downto 0);	-- Read Rt
			i_Imm32		: in std_logic_vector(N-1 downto 0);	-- Immediate (32b)
			i_PCPlus4	: in std_logic_vector(N-1 downto 0);	-- PC + 4
			i_ALUSrc	: in std_logic; -- Choose ALU B to be immediate or Read Rt
			i_ALUOp		: in std_logic_vector(ALU_OP_WIDTH-1 downto 0);	-- Choose ALU instruction
			i_Shamt		: in std_logic_vector(DATA_SELECT-1 downto 0);
			i_SignExt	: in std_logic;
			i_MemWrite 	: in std_logic;
			i_MemRead 	: in std_logic;
			i_MemtoReg	: in std_logic_vector(MEMTOREG_WIDTH - 1 downto 0);
			i_RegWrite	: in std_logic;
			i_RegDst	: in std_logic_vector(REGDST_WIDTH - 1 downto 0);
			i_Movn		: in std_logic;
			--i_Jal		: in std_logic; -- Not needed?
			i_Halt 		: in std_logic;

			o_Rs		: out std_logic_vector(N-1 downto 0);
			o_Rt		: out std_logic_vector(N-1 downto 0);
			o_Rd		: out std_logic_vector(DATA_SELECT-1 downto 0);
			o_ReadRs	: out std_logic_vector(N-1 downto 0);
			o_ReadRt	: out std_logic_vector(N-1 downto 0);
			o_Imm32		: out std_logic_vector(N-1 downto 0);
			o_PCPlus4	: out std_logic_vector(N-1 downto 0);
			o_ALUSrc	: out std_logic;
			o_ALUOp		: out std_logic_vector(ALU_OP_WIDTH-1 downto 0);
			o_Shamt		: out std_logic_vector(DATA_SELECT-1 downto 0);
			o_SignExt	: out std_logic;
			o_MemWrite 	: out std_logic;
			o_MemRead 	: out std_logic;
			o_MemtoReg 	: out std_logic_vector(MEMTOREG_WIDTH - 1 downto 0);
			o_RegWrite 	: out std_logic;
			o_RegDst 	: out std_logic_vector(REGDST_WIDTH - 1 downto 0);
			o_Movn 		: out std_logic;
			--o_Jal 	: out std_logic;
			o_Halt 		: out std_logic);
	end component;

  -- component EXMEM_reg is
  --   generic(N : integer := 32);
  --     port(
  --       i_CLK		: in std_logic;	-- Clock input
  --       i_RST		: in std_logic;	-- Reset input
  --       i_WE		: in std_logic;	-- Write enable
  -- end component;

  -- component MEMWB_reg is
  --   generic(N : integer := 32);
  --     port(
  --       i_CLK		: in std_logic;	-- Clock input
  --       i_RST		: in std_logic;	-- Reset input
  --       i_WE		: in std_logic;	-- Write enable
  -- end component;

  	component regfile is
		generic(N 	  : integer;
				REG_W : integer);
		port(
			i_CLK : in std_logic;		-- Clock input
			i_RST : in std_logic;		-- Reset
			i_We : in std_logic;		-- Write enable
			i_Rs : in std_logic_vector(REG_W - 1 downto 0); -- Register to read 1
			i_Rt : in std_logic_vector(REG_W - 1 downto 0); -- Register to read 2
			i_Rd : in std_logic_vector(REG_W - 1 downto 0); -- Reg being written to
			i_Wd : in std_logic_vector(N -1 downto 0);		-- Data to write to i_Rd
			o_Rs : out std_logic_vector(N -1 downto 0);		-- i_rs data output
			o_Rt : out std_logic_vector(N -1 downto 0));		-- i_rt data output
	end component;

	component extender is
		port(
			i_D : in std_logic_vector((DATA_WIDTH/2)-1 downto 0);
			i_Extend : in std_logic;
			o_F : out std_logic_vector(DATA_WIDTH-1 downto 0));
	end component;

	component control is
		port (
			iOpcode     : in std_logic_vector(OPCODE_WIDTH -1 downto 0); -- 6 MSB of 32bit instruction
			iFunct      : in std_logic_vector(OPCODE_WIDTH - 1 downto 0); -- only for JR
			-- iALUZero : in std_logic; -- TODO: Zero flag from ALU for PC src?
			-- oPCSrc : in std_logic; -- TODO: Selects using PC+4 or branch addy
			oRegDst     : out std_logic_vector(REGDST_WIDTH - 1 downto 0); -- Selects r-type vs i-type write register
			oALUSrc     : out std_logic; -- Selects source for second ALU input (Rt vs Imm)
			oMemtoReg   : out std_logic_vector(MEMTOREG_WIDTH - 1 downto 0); -- Selects ALU result or memory result to reg write
			oRegWrite   : out std_logic; -- Enable register write in datapath->registerfile
			oMemRead    : out std_logic; -- Enable reading of memory in dmem
			oMemWrite   : out std_logic; -- Enable writing to memory in dmem
			oSignExt	  : out std_logic; -- Whether to sign extend the immediate or not
			oJump       : out std_logic; -- Selects setting PC to jump value or not
			oJumpReg	  : out std_logic;
			oMovn       : out std_logic;
			oBranch     : out std_logic; -- Helps select using PC+4 or branch address by being Anded with ALU Zero
			oBranchEQ   : out std_logic; -- Determines if BEQ or BNE
			oALUOp      : out std_logic_vector(ALU_OP_WIDTH - 1 downto 0); -- Selects ALU operation or to select from funct field
			oHalt		: out std_logic); -- Halt port
	end component;

	component ALU is
		port(
			iA 		: in std_logic_vector(DATA_WIDTH - 1 downto 0);
			iB 		: in std_logic_vector(DATA_WIDTH - 1 downto 0);
			iShamt : in std_logic_vector(DATA_SELECT - 1 downto 0);
			iALUOp 	: in std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
			oResult : out std_logic_vector(DATA_WIDTH - 1 downto 0);
			oCout 	: out std_logic;
			oOverflow : out std_logic;
			oZero 	: out std_logic);
	end component;

	component mux2t1_N is
		generic(N : integer := 32); -- Generic of type integer for input/output data width. Default value is 32.
		port(
			i_S 	: in std_logic;
			i_D0	: in std_logic_vector(N-1 downto 0);
			i_D1	: in std_logic_vector(N-1 downto 0);
			o_O 	: out std_logic_vector(N-1 downto 0));
	end component;

	component fetch is
		port(
			i_Addr		: in std_logic_vector(DATA_WIDTH - 1 downto 0); --input address
			i_Jump		: in std_logic; --input 0 or 1 for jump or not jump
			i_JumpReg	: in std_logic; -- jump register instr or not
			i_JumpRegData: in std_logic_vector(DATA_WIDTH - 1 downto 0);
			i_Branch	: in std_logic; --input 0 or 1 for branch or not branch
			i_Zero      : in std_logic;
			i_BEQ   : in std_logic; --input 0 or 1 for branchEQ or BNE
			i_BranchImm	: in std_logic_vector(DATA_WIDTH - 1 downto 0);
			i_JumpImm	: in std_logic_vector(JADDR_WIDTH - 1 downto 0);
			o_Addr		: out std_logic_vector(DATA_WIDTH - 1 downto 0);
			o_PCPlus4	: out std_logic_vector(DATA_WIDTH - 1 downto 0));
	end component;


-- Required data memory signals
signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output

-- Required register file signals 
signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input	
-- Required instruction memory signals
signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_NextInstAddr instead
signal s_NextInstAddr : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
signal s_Inst         : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the instruction signal 	
-- Required halt signal -- for simulation
signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Opcode: 01 0100)	
-- Required overflow signal -- for overflow exception detection
signal s_Ovfl         : std_logic;  -- TODO: this signal indicates an overflow exception would have been initiated

    
--------------------------  CONTROL OUTPUT SIGNALS  --------------------------
signal s_RegDst 	: std_logic_vector(REGDST_WIDTH - 1 downto 0);
signal s_ALUSrc 	: std_logic;
signal s_MemtoReg 	: std_logic_vector(MEMTOREG_WIDTH - 1 downto 0);
-- signal s_RegWrite 	: std_logic; -- s_RegWr replaces this
signal s_MemRead 	: std_logic;
signal s_MemWrite 	: std_logic;
signal s_SignExt	: std_logic;
signal s_Jump 		: std_logic;
signal s_JumpReg	: std_logic;
signal s_Movn		: std_logic;
signal s_Branch 	: std_logic;
signal s_BEQ		: std_logic;
signal s_ALUOp 		: std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
signal s_ALUAction : std_logic_vector(ALU_OP_WIDTH - 1 downto 0);

--------------------------  GENERAL SIGNALS  --------------------------
signal s_UpdatePC : std_logic_vector(DATA_WIDTH - 1 downto 0);			-- Input into PC register
--signal s_WriteRegister : std_logic_vector(DATA_SELECT - 1 downto 0); 	-- Input into regfile i_Rd
signal s_RegWrite : std_logic; -- Input into movn regwrite mux
signal s_ReadRs   : std_logic_vector(DATA_WIDTH - 1 downto 0); -- Output of regfile read Rs
signal s_ReadRt   : std_logic_vector(DATA_WIDTH - 1 downto 0); -- Output of regfile read Rt
signal s_ALUInB   : std_logic_vector(DATA_WIDTH - 1 downto 0); -- 2nd input of ALU (Imm)
signal s_ALUResult: std_logic_vector(DATA_WIDTH - 1 downto 0); -- Result from main alu
signal s_Cout     : std_logic; -- Carry out from ALU
signal s_Zero     : std_logic; -- Zero signal from ALU
signal s_PCPlus4  : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal s_ALUPreMovn:std_logic_vector(DATA_WIDTH - 1 downto 0);
signal s_MovnZero : std_logic;

--------------------------  IF SIGNALS  --------------------------
-- These signals go INTO IF/ID
signal if_Inst    : std_logic_vector(N-1 downto 0);
signal if_PCPlus4 : std_logic_vector(N-1 downto 0);

--------------------------  ID SIGNALS  --------------------------
-- From IF/ID and consumed
signal id_Inst    : std_logic_vector(N-1 downto 0);

-- Created Instruction signals
signal id_Opcode: std_logic_vector(OPCODE_WIDTH - 1 downto 0); -- Opcode
signal id_Funct	: std_logic_vector(FUNCT_WIDTH  - 1 downto 0); -- Funct code
signal id_Imm16	: std_logic_vector(DATA_WIDTH/2 - 1 downto 0); -- Imm field for I-type instruction
signal id_Addr  : std_logic_vector(JADDR_WIDTH  - 1 downto 0); -- Addr width for jump instruction
-- Created instruction signals from control not passed on
signal id_SignExt     : std_logic;
signal id_Jump        : std_logic;
signal id_JumpReg     : std_logic;
signal id_Branch      : std_logic;
signal id_BEQ         : std_logic;

-- These signals go INTO ID/EX
signal id_Rs       : std_logic_vector(DATA_SELECT-1 downto 0);
signal id_Rt       : std_logic_vector(DATA_SELECT-1 downto 0);
signal id_Rd       : std_logic_vector(DATA_SELECT-1 downto 0);
signal id_ReadRs   : std_logic_vector(N-1 downto 0);
signal id_ReadRt   : std_logic_vector(N-1 downto 0);
signal id_Imm32    : std_logic_vector(N-1 downto 0);
signal id_PCPlus4  : std_logic_vector(N-1 downto 0);
signal id_ALUSrc   : std_logic;
signal id_ALUOp    : std_logic_vector(ALU_OP_WIDTH-1 downto 0);
signal id_Shamt    : std_logic_vector(DATA_SELECT-1 downto 0);
signal id_SignExt  : std_logic;
signal id_MemWrite : std_logic;
signal id_MemRead  : std_logic;
signal id_MemtoReg : std_logic_vector(MEMTOREG_WIDTH-1 downto 0);
signal id_RegWrite : std_logic;
signal id_RegDst   : std_logic_vector(REGDST_WIDTH-1 downto 0);
signal id_Movn     : std_logic;
--signal id_Jal    : std_logic;
signal id_Halt     : std_logic;

--------------------------  EX SIGNALS  --------------------------
-- From ID/EX and consumed
signal ex_Rs       : std_logic_vector(DATA_SELECT-1 downto 0);
signal ex_Rt       : std_logic_vector(DATA_SELECT-1 downto 0);
signal ex_Rd       : std_logic_vector(DATA_SELECT-1 downto 0);
signal ex_ReadRs   : std_logic_vector(N-1 downto 0);
signal ex_Imm32    : std_logic_vector(N-1 downto 0);
signal ex_ALUSrc   : std_logic;
signal ex_ALUOp    : std_logic_vector(ALU_OP_WIDTH-1 downto 0);
signal ex_Shamt    : std_logic_vector(DATA_SELECT-1 downto 0);
signal ex_SignExt  : std_logic;

-- These signals go INTO EX/MEM
signal ex_ReadRt	  : std_logic_vector(N-1 downto 0);
signal ex_PCPlus4	  : std_logic_vector(N-1 downto 0);
signal ex_MemWrite 	: std_logic;
signal ex_MemRead 	: std_logic;
signal ex_MemtoReg	: std_logic_vector(MEMTOREG_WIDTH - 1 downto 0);
signal ex_RegWrite	: std_logic;
signal ex_RegDst	  : std_logic_vector(REGDST_WIDTH - 1 downto 0);
signal ex_Movn		  : std_logic;
-- signal ex i_Jal	: std_logic;
signal ex_Halt 		  : std_logic;

--------------------------  MEM SIGNALS  --------------------------
-- From EX/MEM reg and consumed
signal mem_ReadRt	  : std_logic_vector(N-1 downto 0);
signal mem_MemWrite : std_logic;
signal mem_MemRead 	: std_logic;

-- These signals go INTO MEM/WB
signal mem_PCPlus4	: std_logic_vector(N-1 downto 0);
signal mem_MemtoReg	: std_logic_vector(MEMTOREG_WIDTH - 1 downto 0);
signal mem_RegWrite	: std_logic;
signal mem_RegDst	  : std_logic_vector(REGDST_WIDTH - 1 downto 0);
signal mem_Movn		  : std_logic;
--signal mem i_Jal	: std_logic;
signal mem_Halt 		: std_logic;
--------------------------  WB SIGNALS  --------------------------
-- From MEM/WB reg and consumed
-- These signals go INTO IF/ID
signal wb_ReadRt : std_logic_vector(N-1 downto 0);
signal wb_PCPlus4 : std_logic_vector(N-1 downto 0);
signal wb_MemWrite : 
signal wb_MemRead : 
signal wb_MemtoReg : 
signal wb_RegWrite : 
signal wb_RegDst : 
signal wb_Movn : 
signal wb_Halt) : 

begin

  -- TODO: Ensure that s_Halt is connected to an output control signal produced from decoding the Halt instruction (Opcode: 01 0100)
  -- TODO: Ensure that s_Ovfl is connected to the overflow output of your ALU

  --------------------------  INSTRUCTION FETCH (IF) STAGE  --------------------------	
  with iInstLd select
  s_IMemAddr <= s_NextInstAddr when '0',
    iInstAddr when others;

  PC: PC_reg
    generic map(
      N => DATA_WIDTH)
    port map (
      i_CLK => iCLK,
      i_RST => iRST,
      i_WE => '1',
      i_D => if_PCPlus4,
      o_Q => s_NextInstAddr);

  IMem: mem
    generic map(
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => N)
    port map(
      clk  => iCLK,
      addr => s_IMemAddr(11 downto 2),
      data => iInstExt,
      we   => iInstLd,
      q    => s_Inst);

	s_DMemAddr <= s_ALUResult;
	s_DMemData <= s_ReadRt;

  PC: PC_reg
	generic map(
		N => DATA_WIDTH)
	port map (
		i_CLK => iCLK,
		i_RST => iRST,
		i_WE => '1',
		i_D => if_PCPlus4,
		o_Q => s_NextInstAddr);

  if_Inst <= s_Inst;
  --------------------------  INSTRUCTION DECODE (ID) STAGE  --------------------------	
  IFID: IFID_reg
    generic map (N => N)
      port map(
        i_CLK     => iCLK,
        i_RST     => iRST,
        i_WE      => '1',
        i_Inst    => if_Inst,
        i_PCPlus4 => s_NextInstAddr,
        o_Inst    => id_Inst,
        o_PCPlus4 => id_PCPlus4);
  

	id_Opcode(OPCODE_WIDTH - 1 downto 0) <= id_Inst(31 downto 26);
	id_Funct(FUNCT_WIDTH - 1 downto 0) <= id_Inst(5  downto 0);
	id_Rs(DATA_SELECT - 1 downto 0) <= id_Inst(25 downto 21);
	id_Rt(DATA_SELECT - 1 downto 0) <= id_Inst(20 downto 16);
	id_Rd(DATA_SELECT  - 1 downto 0) <= id_Inst(15 downto 11);
	id_Shamt(DATA_SELECT - 1 downto 0) <= id_Inst(10 downto 6);
	id_Addr(JADDR_WIDTH - 1 downto 0) <= id_Inst(25 downto 0);
	id_Imm16(DATA_WIDTH/2 - 1 downto 0) <= id_Inst(15 downto 0);

  Control_Unit: control
	port map (
		iOpcode     => id_Opcode,
		iFunct		  => id_Funct,
		-- iALUZero =>
		-- oPCSrc   =>
		oRegDst     => id_RegDst,
		oALUSrc     => id_ALUSrc,
		oMemtoReg   => id_MemtoReg,
		oRegWrite   => id_RegWrite,
		oMemRead    => id_MemRead,
		oMemWrite   => id_MemWrite,
		oSignExt	=> id_SignExt,
		oJump       => id_Jump,
		oJumpReg	=> id_JumpReg,
		oMovn		=> id_Movn,
		oBranch     => id_Branch,
		oBranchEQ   => id_BEQ,
		oALUOp      => id_ALUOp,
		oHalt		=> id_Halt);
  
    with id_RegDst select
		s_RegWrAddr <=
      id_Rs   when "00",
			id_Rd   when "01",
			"11111" when "10",
			id_Rs   when others;

	-- Selects reg write depending on if MOVN instruction is happening or not, otherwise use control RegWrite
	with s_Movn select
		s_RegWr <=
			(NOT s_Zero)  when '1',
			s_RegWrite    when others;
			

	Regfile_Unit: regfile
	generic map(
		N     => DATA_WIDTH,
		REG_W => DATA_SELECT)
	port map(
		i_CLK	=> iCLK, 
		i_RST	=> iRST, 
		i_We 	=> id_RegWrite, 
		i_Rs 	=> id_Rs,  -- Register to read 1
		i_Rt 	=> id_Rt,  -- Register to read 2
		i_Rd 	=> s_RegWrAddr, -- Reg being written to
		i_Wd 	=> s_RegWrData, -- Data to write to i_Rd
		o_Rs 	=> id_ReadRs, 	-- i_rs data output
		o_Rt 	=> id_ReadRt);	-- i_rt data output

	Sign_Extender: extender
	port map(
		i_D 	 => s_Imm16,
		i_Extend => s_SignExt,
		o_F 	 => s_instr_imm32);

	Fetch_Unit: fetch
	port map(
		i_Addr		  => s_NextInstAddr,
		i_Jump		  => s_Jump,
		i_JumpReg	  => s_JumpReg,
		i_JumpRegData=> s_ReadRs,
		i_Branch	  => s_Branch,
		i_Zero      => s_Zero,
		i_BEQ       => s_BEQ,
		i_BranchImm	=> s_instr_imm32,
		i_JumpImm	  => s_instr_Addr,
		o_Addr		  => s_UpdatePC,
		o_PCPlus4	  => s_PCPlus4);
  --------------------------  EXECUTE (EX) STAGE  --------------------------	
  IDEX: IDEX_reg
    generic map(N => N);
      port map(
        i_CLK => iCLK,
        i_RST => iRST,
        i_WE => '1',
  
        i_Rs      => id_Rs,
        i_Rt      => id_Rt,
        i_Rd      => id_Rd,
        i_ReadRs  => id_ReadRs,
        i_ReadRt  => id_ReadRt,
        i_Imm32   => id_Imm32,
        i_PCPlus4 => id_PCPlus4,
        i_ALUSrc  => id_ALUSrc,
        i_ALUOp   => id_ALUOp,
        i_Shamt   => id_Shamt,
        i_SignExt => id_SignExt,
        i_MemWrite=> id_MemWrite,
        i_MemRead => id_MemRead,
        i_MemtoReg=> id_MemtoReg,
        i_RegWrite=> id_RegWrite,
        i_RegDst  => id_RegDst,
        i_Movn    => id_Movn,
        i_Halt    => id_Halt,
  
        o_Rs      => ex_Rs,
        o_Rt      => ex_Rt,
        o_Rd      => ex_Rd,
        o_ReadRs  => ex_ReadRs,
        o_ReadRt  => ex_ReadRt,
        o_Imm32   => ex_Imm32,
        o_PCPlus4 => ex_PCPlus4,
        o_ALUSrc  => ex_ALUSrc,
        o_ALUOp   => ex_ALUOp,
        o_Shamt   => ex_Shamt,
        o_SignExt => ex_SignExt,
        o_MemWrite=> ex_MemWrite,
        o_MemRead => ex_MemRead,
        o_MemtoReg=> ex_MemtoReg,
        o_RegWrite=> ex_RegWrite,
        o_RegDst  => ex_RegDst,
        o_Movn    => ex_Movn,
        o_Halt    => ex_Halt);
  
  ALUSrc_mux: mux2t1_N
	generic map(
		N => DATA_WIDTH)
	port map(
		i_S  => s_ALUSrc,
		i_D0 => s_ReadRt,
		i_D1 => s_instr_imm32,
		o_O  => s_ALUInB);

	ALU_Main: ALU
	port map (
		iA			  => s_ReadRs,
    iB			  => s_ALUInB,
		iShamt		=> s_instr_Shamt,
    iALUOp		=> s_ALUAction,
    oResult		=> s_ALUPreMovn,
    oCout		  => s_Cout,
    oOverflow	=> s_Ovfl, -- Given Signal
    oZero		  => s_Zero);


	-- Movn mux after ALU
	with (s_Movn AND (NOT s_Zero)) select
		s_ALUResult <=
			s_ReadRs when '1',
			s_ALUPreMovn when others;


  oALUOut <= s_ALUResult;
  --------------------------  MEMORY (MEM) STAGE  --------------------------	
  EXMEM: EXMEM_reg
  generic map(N => N);
    port map(
      i_CLK => iCLK,
      i_RST => iRST,
      i_WE => '1',

      i_ReadRt  => ex_ReadRt,
      i_PCPlus4 => ex_PCPlus4,
      i_MemWrite=> ex_MemWrite,
      i_MemRead => ex_MemRead,
      i_MemtoReg=> ex_MemtoReg,
      i_RegWrite=> ex_RegWrite,
      i_RegDst  => ex_RegDst,
      i_Movn    => ex_Movn,
      i_Halt    => ex_Halt,

      i_ReadRt  => mem_ReadRt,
      i_PCPlus4 => mem_PCPlus4,
      i_MemWrite=> mem_MemWrite,
      i_MemRead => mem_MemRead,
      i_MemtoReg=> mem_MemtoReg,
      i_RegWrite=> mem_RegWrite,
      i_RegDst  => mem_RegDst,
      i_Movn    => mem_Movn,
      i_Halt    => mem_Halt);
  

  DMem: mem
  generic map(ADDR_WIDTH => ADDR_WIDTH,
              DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             we   => s_DMemWr,
             q    => s_DMemOut);

  --------------------------  WRITE BACK (WB) STAGE  --------------------------	
  MEMWB: MEMWB_reg
  generic map(N => N);
    port map(
      i_CLK => iCLK,
      i_RST => iRST,
      i_WE => '1',

      i_PCPlus4 => mem_PCPlus4,
      i_MemtoReg=> mem_MemtoReg,
      i_RegWrite=> mem_RegWrite,
      i_RegDst  => mem_RegDst,
      i_Movn    => mem_Movn,
      i_Halt    => mem_Halt,

      i_PCPlus4 => wb_PCPlus4,
      i_MemtoReg=> wb_MemtoReg,
      i_RegWrite=> wb_RegWrite,
      i_RegDst  => wb_RegDst,
      i_Movn    => wb_Movn,
      i_Halt    => wb_Halt);



with s_MemtoReg select
		s_RegWrData <=
		s_ALUResult when "00",
		s_DMemOut when "01",
		s_PCPlus4 when "10",
		s_ALUResult when others;


end structure;

