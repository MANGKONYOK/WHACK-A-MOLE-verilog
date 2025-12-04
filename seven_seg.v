module seven_seg (
    input wire clk,             // ใช้ clk 1kHz (จาก clk_divider)
    input wire [6:0] score_in,  // รับคะแนน (จาก Data Storage)
    input wire [6:0] time_in,   // รับเวลา (จาก Data Storage)
    output reg [6:0] seg,       // ต่อขา cathode (a-g)
    output reg [3:0] an         // ต่อขา anode
);
    // ข้างในต้องมี:
    // 1. Logic แยกหลักหน่วย/หลักสิบ (Mod/Div หรือ Lookup Table)
    // 2. State Machine หรือ Counter เล็กๆ เพื่อสลับไฟทีละหลัก (Multiplexing)
    // 3. ตัวแปลงเลข 0-9 เป็น pattern ไฟ a-g
    // ใน Basys3 ใช้ 7-seg 4 หลักแล้วจะแบ่ง/จอซ้ายไว้สำหรับ time countdown จอขวาสำหรับคะแนนอย่างละสองหลัก
endmodule