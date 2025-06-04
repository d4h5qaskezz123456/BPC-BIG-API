tableextension 80197 "BPC.StockkeepingUnit" extends "Stockkeeping Unit"
{
    fields
    {
        //Kim 2025-03 ++
        field(80000; "BPC.Brand"; code[30])
        {
            Caption = 'Brand';
            Editable = false;
            // FieldClass = FlowField;
            // CalcFormula = lookup(Item."BPC.Brand" where("No." = field("Item No.")));
        }
        //Kim 2025-03 --
        //Oat 20250527 ++
        // field(80001; "BPC Location Type"; Enum "BPC Location Type")
        // {
        //     Caption = 'Location Type';
        //     // FieldClass = FlowField;
        //     // CalcFormula = lookup(Location."BPC Location Type" where(Code = field("Location Code")));
        // }
        //Oat 20250527 --
    }
}
