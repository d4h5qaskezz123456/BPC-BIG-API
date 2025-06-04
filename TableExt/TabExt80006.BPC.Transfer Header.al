tableextension 80006 "BPC Transfer Header" extends "Transfer Header"
{
    fields
    {

        field(80100; "BPC.Interface"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Interface';
        }
        field(80101; "BPC.Active"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Active';
        }

        field(80102; "BPC.New Dimension Set ID"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'New Dimension Set ID';
        }
        field(80103; "BPC.New Short Dimension 1 Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'New Shortcut Dimension 1 Code';
            trigger OnValidate()
            var
                myInt: Integer;
            begin
                ValidateNewShortcutDimCode(rec, 1, "LSC New Shortcut Dim. 1 Code");
            end;
        }
        field(80104; "BPC.New Short Dimension 2 Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'New Shortcut Dimension 2 Code';
            trigger OnValidate()
            var
                myInt: Integer;
            begin
                ValidateNewShortcutDimCode(rec, 2, "LSC New Shortcut Dim. 2 Code");
            end;
        }
        field(80105; "BPC.Retail Status"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Retail Status';
            OptionMembers = New,Sent,"Part. receipt","Closed - ok","Closed - difference","To receive","Planned receive",Approved,Decline;
        }
        field(80106; "BPC.HN/AN No."; code[35])
        {
            Caption = 'HN/AN No.';
        }

    }


    local procedure ValidateNewShortcutDimCode(var TransferHeader: Record "Transfer Header"; FieldNumber: Integer; Var NewShortcutDimCode: code[20])
    var
        myInt: Integer;
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, NewShortcutDimCode, TransferHeader."BPC.New Dimension Set ID");
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        Store: Record "LSC Store";
        TableID: array[10] of Integer;
        No: array[10] of Code[10];
        TransferHeader: Record "Transfer Header";
        SourceCodeSetup: Record "Source Code Setup";
        lStore: Record "LSC Store";
        RetailTransferOrderExt: Codeunit "LSC Retail Transfer Order Ext.";
}