/*
 * APS2.h
 *
 * APS2 Specfic Structures and tools
 */


#ifndef APS2_H
#define APS2_H

#include <cstdint>
#include <string>

using std::string;

class APS2 {

public:
	//Some bitfield unions for packing/unpacking the commands words
	//APS Command Protocol 
	//ACK SEQ SEL R/W CMD<3:0> MODE/STAT CNT<15:0>
	//31 30 29 28 27..24 23..16 15..0
	//ACK .......Acknowledge Flag. Set in the Acknowledge Packet returned in response to a
	// Command Packet. Must be zero in a Command Packet.
	// SEQ............Set for Sequence Error. MODE/STAT = 0x01 for skip and 0x00 for duplicate.
	// SEL........Channel Select. Selects target for commands with more than one target. Zero
	// if not used. Unmodified in the Acknowledge Packet.
	// R/W ........Read/Write. Set for read commands, cleared for write commands. Unmodified
	// in the Acknowledge Packet.
	// CMD<3:0> ....Specifies the command to perform when the packet is received by the APS
	// module. Unmodified in the Acknowledge Packet. See section 3.8 for
	// information on the supported commands.
	// MODE/STAT....Command Mode or Status. MODE bits modify the operation of some
	// commands. STAT bits are returned in the Acknowledge Packet to indicate
	// command completion status. A STAT value of 0xFF indicates an invalid or
	// unrecognized command. See individual command descriptions for more
	// information.
	// CNT<15:0> ...Number of 32-bit data words to transfer for a read or a write command. Note
	// that the length does NOT include the Address Word. CNT must be at least 1.
	// To meet Ethernet packet length limitations, CNT must not exceed 366.
	typedef union {
		struct {
		uint32_t cnt : 16;
		uint32_t mode_stat : 8;
		uint32_t cmd : 4;
		uint32_t r_w : 1;
		uint32_t sel : 1;
		uint32_t seq : 1;
		uint32_t ack : 1;
		};
		uint32_t packed;
	} APSCommand_t;



	//Chip config SPI commands for setting up DAC,PLL,VXCO
	//Possible target bytes
	// 0x00 ............Pause commands stream for 100ns times the count in D<23:0>
	// 0xC0/0xC8 .......DAC Channel 0 Access (AD9736)
	// 0xC1/0xC9 .......DAC Channel 1 Access (AD9736)
	// 0xD0/0xD8 .......PLL Clock Generator Access (AD518-1)
	// 0xE0 ............VCXO Controller Access (CDC7005)
	// 0xFF ............End of list
	typedef union  {
		struct {
		uint32_t instr : 16; // SPI instruction for DAC, PLL instruction, or 0
		uint32_t spicnt_data: 8; // data byte for single byte or SPI insruction
		uint32_t target : 8; 
		};
		uint32_t packed;
	} APSChipConfigCommand_t;

	//PLL commands 
	// INSTR<12..0> ......ADDR. Specifies the address of the register to read or write.
	// INSTR<14..13> .....W<1..0>. Specified transfer length. 00 = 1, 01 = 2, 10 = 3, 11 = stream
	// INSTR<15> .........R/W. Read/Write select. Read = 1, Write = 0.
	typedef union  {
		struct {
		uint16_t addr : 13;
		uint16_t W  :  2;
		uint16_t r_w : 1;
		};
		uint16_t packed;
	} PLLCommand_t;

	//DAC Commands
	// INSTR<4..0> ......ADDR. Specifies the address of the register to read or write.
	// INSTR<6..5> ......N<1..0>. Specified transfer length. Only 00 = single byte mode supported.
	// INSTR<7> ..........R/W. Read/Write select. Read = 1, Write = 0.
	typedef union {
		struct {
		uint8_t addr : 5;
		uint8_t N  :  2;
		uint8_t r_w : 1;
		};
		uint8_t packed;
	} DACCommand_t;

	static const uint16_t NUM_STATUS_REGISTERS = 16;

	enum APS_COMMANDS {
		APS_COMMAND_RESET           = 0x0,
		APS_COMMAND_USERIO_ACK      = 0x1,
		APS_COMMAND_USERIO_NACK     = 0x9,
		APS_COMMAND_EPROMIO         = 0x2,
		APS_COMMAND_CHIPCONFIGIO    = 0x3,
		APS_COMMAND_RUNCHIPCONFIG   = 0x4,
		APS_COMMAND_FPGACONFIG_ACK  = 0x5,
		APS_COMMAND_FPGACONFIG_NACK = 0xD,
		APS_COMMAND_FPGACONFIG_CTRL = 0x6,
		APS_COMMAND_STATUS          = 0x7
	};

	enum APS_STATUS {
		APS_STATUS_HOST   = 0,
		APS_STATUS_VOLT_A = 1,
		APS_STATUS_VOLT_B = 2,
		APS_STATUS_TEMP   = 3
	};

	enum APS_ERROR_CODES {
		APS_SUCCESS = 0,
		APS_INVALID_CNT = 1,
	};

	enum RESET_MODE_STAT {
		RESET_RECONFIG_BASELINE_EPROM = 0,
		RESET_RECONFIG_USER_EPROM     = 1,
		RESET_SOFT_RESET_HOST_USER    = 2,
		RESET_SOFT_RESET_USER_ONLY    = 3
	};

	enum USERIO_MODE_STAT {
		USERIO_SUCCESS = APS_SUCCESS,
		USERIO_INVALID_CNT = APS_INVALID_CNT,
		USERIO_USER_LOGIC_TIMEOUT = 2,
		USERIO_RESERVED = 3,
	};

	enum EPROMIO_MODE_STAT {
		EPROM_RW_256B = 0,
		EPROM_ERASE_64K = 1,
		EPROM_SUCCESS = 0,
		EPROM_INVALID_CNT = 1,
		EPROM_OPPERATION_FAILED = 4
	};

	enum CHIPCONFIGIO_MODE_STAT {
		CHIPCONFIG_SUCCESS = APS_SUCCESS,
		CHIPCONFIG_INVALID_CNT = APS_INVALID_CNT,
		CHIPCONFIG_INVALID_TARGET = 2,
	};

	enum CHIPCONFIG_IO_TARGET {
		CHIPCONFIG_TARGET_PAUSE = 0,
		CHIPCONFIG_TARGET_DAC_0 = 1,
		CHIPCONFIG_TARGET_DAC_1 = 2,
		CHIPCONFIG_TARGET_PLL = 3,
		CHIPCONFIG_TARGET_VCXO = 4
	};

	enum CHIPCONFIG_IO_TARGET_CMD {
		CHIPCONFIG_IO_TARGET_PAUSE        = 0,
		CHIPCONFIG_IO_TARGET_DAC_0_MULTI  = 0xC0, // multiple byte length in SPI cnt
		CHIPCONFIG_IO_TARGET_DAC_1_MULTI  = 0xC1, // multiple byte length in SPI cnt
		CHIPCONFIG_IO_TARGET_PLL_MULTI    = 0xD0, // multiple byte length in SPI cnt
		CHIPCONFIG_IO_TARGET_DAC_0_SINGLE = 0xC8, // single byte payload
		CHIPCONFIG_IO_TARGET_DAC_1_SINGLE = 0xC9, // single byte payload
		CHIPCONFIG_IO_TARGET_PLL_SINGLE   = 0xD8, // single byte payload
		CHIPCONFIG_IO_TARGET_VCXO         = 0xE0, 
		CHIPCONFIG_IO_TARGET_EOL          = 0xFF, // end of list
	};

	enum RUNCHIPCONFIG_MODE_STAT {
		RUNCHIPCONFIG_SUCCESS = APS_SUCCESS,
		RUNCHIPCONFIG_INVALID_CNT = APS_INVALID_CNT,
		RUNCHIPCONFIG_INVALID_OFFSET = 2,
	};

	enum FPGACONFIG_MODE_STAT {
		FPGACONFIG_SUCCESS = APS_SUCCESS,
		FPGACONFIG_INVALID_CNT = APS_INVALID_CNT,
		FPGACONFIG_INVALID_OFFSET = 2,
	};

	enum STATUS_REGISTERS {
		HOST_FIRMWARE_VERSION = 0,
		USER_FIRMWARE_VERSOIN = 1,
		CONFIGURATION_SOURCE = 2,
		USER_STATUS = 3,
		DAC0_STATUS = 4,
		DAC1_STATUS = 5,
		PLL_STATUS = 6,
		VCXO_STATUS = 7,
		SEND_PACKET_COUNT = 8,
		RECEIVE_PACKET_COUNT = 9,
		SEQUENCE_SKIP_COUNT = 0xA,
		SEQUENCE_DUP_COUNT = 0xB,
		UPTIME = 0xC,
		RESERVED1 = 0xD,
		RESERVED2 = 0xE,
		RESERVED3 = 0xF,
	};

	struct APS_Status_Registers {
		uint32_t hostFirmwareVersion;
		uint32_t userFirmwareVersion;
		uint32_t configurationSource;
		uint32_t userStatus;
		uint32_t dac0Status;
		uint32_t dac1Status;
		uint32_t pllStatus;
		uint32_t vcxoStatus;
		uint32_t sendPacketCount;
		uint32_t receivePacketCount;
		uint32_t sequenceSkipCount;
		uint32_t sequenceDupCount;
		uint32_t uptime;
		uint32_t reserved1;
		uint32_t reserved2;
		uint32_t reserved3;
	};

	enum CONFIGURATION_SOURCE {
		BASELINE_IMAGE = 0xBBBBBBBB,
		USER_EPROM_IMAGE = 0xEEEEEEEE
	};

	//PLL routines go through sets of address/data pairs
	typedef std::pair<uint16_t, uint8_t> AddrData;
	
	//
	uint32_t * getPayloadPtr(uint32_t * frame);
	

	string printStatusRegisters(const APS_Status_Registers & status);

	string printAPSCommand(const APSCommand_t & command);
	string printAPSChipCommand(APSChipConfigCommand_t & command);

	static const int NUM_CHANNELS = 2;


	//Constructors
	APS2();
	APS2(int, string);
	~APS();

	int connect();
	int disconnect();

	int init(const bool & = false, const int & bitFileNum);
	int reset();

	int load_bitfile(const string &, const int &);
	int program_bitfile(const int &);
	int get_bitfile_version() const;

	int setup_VCXO() const;
	int setup_PLL() const;
	int setup_DACs();

	int set_sampleRate(const int &);
	int get_sampleRate();

	int set_trigger_source(const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source();
	int set_trigger_interval(const double &);
	double get_trigger_interval();

	int set_channel_enabled(const int &, const bool &);
	bool get_channel_enabled(const int &) const;
	int set_channel_offset(const int &, const float &);
	float get_channel_offset(const int &) const;
	int set_channel_scale(const int &, const float &);
	float get_channel_scale(const int &) const;
	int set_offset_register(const int &, const float &);

	template <typename T>
	int set_waveform(const int & dac, const vector<T> & data){
		channels_[dac].set_waveform(data);
		return write_waveform(dac, channels_[dac].prep_waveform());
	}

	int set_run_mode(const int &, const RUN_MODE &);

	int set_LLData_IQ(const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);
	int clear_channel_data();

	int load_sequence_file(const string &);

	int run();
	int stop();

	//The owning APSRack needs access to some private members
	friend class APSRack;

	//Whether the APS connection is open
	bool isOpen;

private:

	int deviceID_;
	string deviceSerial_;
	EthernetControl handle_;
	vector<Channel> channels_;
	int samplingRate_;
	vector<UCHAR> writeQueue_;

	int write(const unsigned int & addr, const uint32_t & data, const bool & queue = false);
	int write(const unsigned int & addr, const vector<uint32_t> & data, const bool & queue = false);

	int flush();

	int setup_PLL();
	int set_PLL_freq(const int &);

	int setup_VCXO();

	int setup_DAC(const int &);
	int enable_DAC_FIFO(const int &);
	int disable_DAC_FIFO(const int &);

	// int trigger();
	// int disable();

	int write_waveform(const int &, const vector<short> &);

	int write_LL_data_IQ(const ULONG &, const size_t &, const size_t &, const bool &);
	int set_LL_data_IQ(const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);

	// int save_state_file(string &);
	// int read_state_file(string &);
	// int write_state_to_hdf5(  H5::H5File & , const string & );
	// int read_state_from_hdf5( H5::H5File & , const string & );

	
} //end class APS2




#endif /* APS2_H_ */
