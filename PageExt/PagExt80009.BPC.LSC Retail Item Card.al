pageextension 80009 "BPC.LSC Retail Item Card" extends "LSC Retail Item Card"
{
    layout
    {
        addafter("Automatic Ext. Texts")
        {
            field("BPC.Model"; Rec."BPC.Model")
            {
                ApplicationArea = all;
            }
            field("BPC.Model Description"; Rec."BPC.Model Description")
            {
                ApplicationArea = all;
            }
            field("BPC.Type"; Rec."BPC.Type")
            {
                ApplicationArea = all;
            }
            field("BPC.Type Description"; Rec."BPC.Type Description")
            {
                ApplicationArea = all;
            }
            field("BPC.Size"; Rec."BPC.Size")
            {
                ApplicationArea = all;
            }
            field("BPC.Size Description"; Rec."BPC.Size Description")
            {
                ApplicationArea = all;
            }
            field("BPC.Type 1"; Rec."BPC.Type 1")
            {
                ApplicationArea = all;
            }
            field("BPC.Type1 Description"; Rec."BPC.Type1 Description")
            {
                ApplicationArea = all;
            }
            field("BPC.Type 2"; Rec."BPC.Type 2")
            {
                ApplicationArea = all;
            }
            field("BPC.Type2 Description"; Rec."BPC.Type2 Description")
            {
                ApplicationArea = all;
            }
            field("BPC.Modified date and time"; Rec."BPC.Modified date and time")
            {
                ApplicationArea = all;
            }
        }
        //--A-- 2024/11/15 ++
        addbefore("Date Created")
        {
            field("Prevent Negative Inventory"; Rec."Prevent Negative Inventory")
            {
                ApplicationArea = all;
            }
        }
        addafter(Type)
        {
            field("BPC.Block Update Type"; Rec."BPC.Block Update Type")
            {
                ApplicationArea = all;
                ToolTip = 'เมื่อมีการ API กับ FO จะไม่ Update ฟิลล์ Type';
            }
        }
        //--A-- 2024/11/15 --
    }

    actions
    {


    }

    var


}