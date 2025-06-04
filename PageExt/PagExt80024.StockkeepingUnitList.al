pageextension 80024 "BPC.StockkeepingUnitList" extends "Stockkeeping Unit List"
{

    layout
    {
        //Oat PD-API Modify page 20250527 ++
        modify("Variant Code")
        {
            Visible = false;
        }
        modify("Replenishment System")
        {
            Visible = false;
        }
        moveafter("Item No."; Description)
        addafter(Description)
        {
            field("BPC.Brand"; Rec."BPC.Brand")
            {
                ApplicationArea = All;
                Visible = true;
            }
        }
        moveafter("Location Code"; Inventory)
        //Oat --
    }

    trigger OnOpenPage()
    // var
    //     Options: Text;
    //     ShowTopText: Label 'Choose one "Location Type" of the following options';
    //     Selected: Integer;
    begin
        // Options := '1. Sales,2. Head Office,3. Claim Service,4. All';
        // Selected := Dialog.StrMenu(Options, 1, ShowTopText);
        // case Selected of
        //     0:
        //         error('');
        //     1:
        //         Rec.SetRange("BPC Location Type", "BPC Location Type"::Sales);
        //     2:
        //         Rec.SetRange("BPC Location Type", "BPC Location Type"::"Head Office");
        //     3:
        //         Rec.SetRange("BPC Location Type", "BPC Location Type"::Claim);
        //     4:
        //         ;
        // end;
        Rec.SetFilter(Inventory, '>%1', 0);
        Rec.SetLoadFields("Item No.", Description, "BPC.Brand", "Location Code", Inventory);
    end;
}