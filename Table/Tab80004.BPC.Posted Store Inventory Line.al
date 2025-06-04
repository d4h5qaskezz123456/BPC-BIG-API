table 80004 "BPC.Posted Store InventoryLine"
{
    Caption = 'Posted Store Inventory Line';
    DataCaptionFields = Description;

    fields
    {
        field(1; WorksheetSeqNo; Integer)
        {
            Caption = 'WorksheetSeqNo';
            NotBlank = true;
            TableRelation = "LSC Store Inventory Worksheet";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnLookup()
            var
                Item: Record Item;
                StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
                PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
            begin
            end;

            trigger OnValidate()
            var
                StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
                StoreInventoryLineBuffer: Record "LSC Store Inventory Worksheet" temporary;
                ErrorText: Text;
            begin
            end;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
                StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
            begin
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
                ErrorText: Text;
            begin
                IF Rec."Entry Type" = Rec."Entry Type"::"Negative Adjmt." THEN BEGIN
                    Rec."Quantity Negative-" := -ABS(Rec.Quantity);
                END ELSE BEGIN
                    Rec."Quantity Negative-" := Rec.Quantity;
                END;
            end;
        }
        field(14; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                ItemUOM: Record "Item Unit of Measure";
                ErrorText: Text;
            begin
            end;
        }
        field(15; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;

            trigger OnLookup()
            var
                Vendor: Record Vendor;
            begin
            end;

            trigger OnValidate()
            var
                ErrorText: Text;
            begin
            end;
        }
        field(16; "Vendor Item No."; Text[20])
        {
            Caption = 'Vendor Item No.';
        }
        field(30; "New Location Code"; Code[10])
        {
            Caption = 'New Location Code';
            TableRelation = Location;
        }
        field(31; "New Store Code"; Code[10])
        {
            Caption = 'New Store Code';
            TableRelation = "LSC Store";

            trigger OnValidate()
            var
                Store: Record "LSC Store";
            begin
            end;
        }
        field(40; "Competitor Price"; Decimal)
        {
            Caption = 'Competitor Price';
        }
        field(50; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
        }
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            Editable = false;
            InitValue = 1;
        }
        field(54; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(56; "Qty. (Calculated)"; Decimal)
        {
            Caption = 'Qty. (Calculated)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(57; "Qty. (Phys. Inventory)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory)';
            DecimalPlaces = 0 : 5;
        }
        field(60; "Area Code"; Code[10])
        {
            Caption = 'Area Code';
            TableRelation = "LSC Store Invt. Counting Area".Area WHERE(WorksheetSeqNo = FIELD(WorksheetSeqNo));
        }
        field(482; "Date Time"; DateTime)
        {
            Caption = 'Date Time';
        }
        field(483; "Retail User"; Code[50])
        {
            Caption = 'Retail User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "LSC Retail User";
        }
        field(490; Barcode; Code[20])
        {
            Caption = 'Barcode';

            trigger OnValidate()
            var
                Item: Record Item;
                Barcodes: Record "LSC Barcodes";
                BarcodeMgmt: Codeunit "LSC Barcode Management";
                EnteredBarcode: Code[20];
                DummyPrice: Decimal;
                Qty: Decimal;
            begin
            end;
        }
        field(500; "Line Log"; Integer)
        {
            CalcFormula = Count("LSC Store Inventory Line Log" WHERE(WorksheetSeqNo = FIELD(WorksheetSeqNo),
                                                                  "Store Inv. Line No." = FIELD("Line No.")));
            Caption = 'Line Log';
            Editable = false;
            FieldClass = FlowField;
        }
        field(501; "Worksheet Log"; Integer)
        {
            CalcFormula = Count("LSC Store Inventory Line Log" WHERE(WorksheetSeqNo = FIELD(WorksheetSeqNo)));
            Caption = 'Worksheet Log';
            Editable = false;
            FieldClass = FlowField;
        }
        field(503; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            Editable = false;
            OptionCaption = 'Positive Adjmt.,Negative Adjmt.';
            OptionMembers = "Positive Adjmt.","Negative Adjmt.";
        }
        field(504; "Transaction No."; Code[20])
        {
            Caption = 'Transaction No.';
        }
        field(505; "Transaction Line No."; Integer)
        {
            Caption = 'Transaction Line No.';
        }
        field(50000; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = ToBeClassified;
            Description = 'Ton 2020/04/28';
        }
        field(50001; "Journal ID"; Code[20])
        {
            Caption = 'Journal ID';
            DataClassification = ToBeClassified;
            Description = 'Ton 2020/05/25';
        }
        field(50002; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = ToBeClassified;
            Description = 'Ton 2020/05/25';
        }
        field(50003; "Quantity Negative-"; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = ToBeClassified;
            Description = 'Tar 2023/04/06';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StoreInventoryLineLog: Record "LSC Store Inventory Line Log";
    begin
    end;

    trigger OnInsert()
    var
        RetailSetup: Record "LSC Retail Setup";
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
    begin
    end;

    trigger OnModify()
    var
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
    begin
    end;

    procedure RunEntryNo(): Integer
    var
        PostedStoreInventoryLine: Record "BPC.Posted Store InventoryLine";
        EntryNo: Integer;
    begin
        PostedStoreInventoryLine.RESET;
        IF PostedStoreInventoryLine.FINDLAST THEN BEGIN
            EntryNo := PostedStoreInventoryLine."Entry No." + 1;
        END ELSE BEGIN
            EntryNo := 1;
        END;

        EXIT(EntryNo);
    end;
}

