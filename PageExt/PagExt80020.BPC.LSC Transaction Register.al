pageextension 80020 "BPC.LSC Transaction Register" extends "LSC Transaction Register"
{
    layout
    {
    }
    actions
    {
        addlast("&Print")
        {
            action(ReSendPostSalesShipment_POS)
            {
                ApplicationArea = all;
                Caption = 'Re-Send Interface to D365';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    myInt: Integer;
                begin
                    RetailSetup.Get();
                    RetailSetup.TestField("bpc.Interface D365 Active");
                    if rec."BPC.Sales Order No." <> '' then
                        ReSendInterfacePOS.PostSalesShipment_POS(Rec)
                    else
                        Error('No sales order no.');
                end;
            }
            action(test)
            {
                ApplicationArea = all;
                Caption = 'Gen Json postStmtJournal';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                //Visible = false;
                trigger OnAction()
                var
                    InterfaceData: Codeunit "BPC.Interface Data";
                    RecRef: RecordRef;
                    pRec: Record "LSC Posted Statement";
                    pText: Text;
                begin
                    pRec.Reset();
                    //pRec.SetRange("No.", 'T0682411-005');//DP
                    //pRec.SetRange("No.", 'T01624-001');//Use DP
                    pRec.SetRange("No.", Rec."Statement No.");
                    if pRec.FindSet() then begin
                        RecRef.GetTable(pRec);
                        pText := InterfaceData.CreateJsonRequestStr('postStmtJournal', RecRef);
                        Message(pText);
                    end;
                end;
            }
            action(test2)
            {
                ApplicationArea = all;
                Caption = 'Gen Json postStmtMovement';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                //Visible = false;
                trigger OnAction()
                var
                    InterfaceData: Codeunit "BPC.Interface Data";
                    RecRef: RecordRef;
                    pRec: Record "LSC Posted Statement";
                    pText: Text;
                begin
                    pRec.Reset();
                    pRec.SetRange("No.", Rec."Statement No.");
                    if pRec.FindSet() then begin
                        RecRef.GetTable(pRec);
                        pText := InterfaceData.CreateJsonRequestStr('postStmtMovement', RecRef);
                        Message(pText);
                    end;
                end;
            }
            action(test3)
            {
                ApplicationArea = all;
                Caption = 'RoundToInt';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                Visible = false;
                trigger OnAction()
                var
                    InterfaceData: Codeunit "BPC.Interface Data";
                    RecRef: RecordRef;
                    pRec: Record "LSC Posted Statement";
                    pText: Text;
                begin
                    Message('RoundToInt %1', RoundToInt(30101));
                end;
            }

        }
    }
    procedure RoundToInt(pInt: Integer): Integer
    var
        myInt: Integer;
        TmpInt: Text;
    begin
        if pInt <> 0 then begin
            TmpInt := Format(pInt);
            TmpInt := CopyStr(TmpInt, StrLen(TmpInt), 1);
            if TmpInt <> '' then
                Evaluate(myInt, TmpInt);
            exit(pInt - myInt);
        end;
    end;

    var
        LSCTransactionHeader: Record "Transfer Shipment Header";
        ReSendInterfacePOS: Codeunit "BPC.Interface POS";
        RetailSetup: Record "LSC Retail Setup";

}