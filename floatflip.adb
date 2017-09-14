--
pragma Ada_2012;
with unchecked_conversion;
with Ada.Float_Text_IO; use Ada.Float_Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Text_IO; use Ada.Text_IO;

-- main procedure
procedure floatflip is
   -- all types and subtypes
   type Bit is mod 2;
   type BitString is array(0..31) of Bit
     with Pack;
   subtype middle_Binary_Range is Natural range BitString'last - 8.. BitString'last - 1;
   subtype end_Binary_Range is Natural range BitString'first.. BitString'last - 9;
   type slice_Middle_Type is array(middle_Binary_Range) of Bit;
   type slice_End_Type is array(end_Binary_Range) of Bit;
   type regular_8Bit_Array is array(0..7) of Bit;
   package bitIO is new ada.Text_IO.Modular_IO(Bit); use bitIO;
   function copy_bits is new Unchecked_Conversion(source => float, target => BitString);
   function back_to_float is new Unchecked_Conversion(source => BitString, target => float);

   -- prints the binary of a number
   procedure printFormattedBinary(bitArray: BitString) is
     begin
      for i in reverse bitArray'range  loop
         if i = bitArray'last - 1 or i = bitArray'last - 9 then
            put(":");
         end if;
         if i mod 4 = 2 and i /= bitArray'Last - 1 then
            put(" ");
         end if;
         put(bitArray(i),1);
      end loop;
   end printFormattedBinary;

   -- put slice type back to bitstring
   procedure print(bitArray: slice_End_Type) is
   begin
      for i in reverse bitArray'range loop
         if i mod 4 = 2 and i /= bitArray'Last then
            put(" ");
            put(bitArray(i),1);
         else
              put(bitArray(i),1);
         end if;
      end loop;
   end print;
   -- gets the slice for middle part of binary number
   function retNewMiddleSlice(allBits: BitString) return slice_Middle_Type is
      new_Middle_Slice: slice_Middle_Type;
      counter: Integer := 0;
   begin
      for i in reverse allBits'range loop
         if i in middle_Binary_Range then
            new_Middle_Slice(i) := allBits(i);
         end if;
      end loop;
      return new_Middle_Slice;
   end retNewMiddleSlice;

   -- function that returns end part of binary number
   function retNewEndSlice(allBits: BitString) return slice_End_Type is
      new_End_Slice: slice_End_Type;
   begin
      for i in reverse allBits'range loop
         if i in end_Binary_Range then
            new_End_Slice(i) := allBits(i);
         end if;
      end loop;
      return new_End_Slice;
   end retNewEndSlice;

   -- helper function for calculate exponent num
   function convertToRegIndecies(slicedArray: slice_Middle_Type) return regular_8Bit_Array is
      newArr: regular_8Bit_Array;
      counter: Integer := 0;
   begin
      for i in slicedArray'Range loop
         newArr(counter) := slicedArray(i);
         counter := counter + 1;
      end loop;
      return newArr;
   end convertToRegIndecies;


   -- function to calculate middle number
   function calculateExpoNum(slicedArray: slice_Middle_Type) return Integer is
      newBitValue: Integer := 0;
      convertedInt: Integer := 0;
      newArr: regular_8Bit_Array := convertToRegIndecies(slicedArray);
   begin
      for i in reverse newArr'range loop
         convertedInt := Integer(newArr(i));
         newBitValue := newBitValue + (convertedInt * 2**i);
      end loop;
      newBitValue := newBitValue - 127;
      if newBitValue = -127 then
         newBitValue := -126;
      end if;
      return newBitValue;
   end calculateExpoNum;

   -- reverses the middle slice of original binary
   function reverseMiddleSlice(otherWayBinary: slice_Middle_Type) return slice_Middle_Type is
      reverseMiddleSection: slice_Middle_Type;
      lastIndex:Integer := otherWayBinary'Last;
   begin
      for i in otherWayBinary'range loop
         reverseMiddleSection(lastIndex) := otherWayBinary(i);
         lastIndex := lastIndex - 1;
      end loop;
      return reverseMiddleSection;
   end reverseMiddleSlice;

   -- reverses the end slice of the original binary
   function reverseEndSlice(otherWayBinary: slice_End_Type) return slice_End_Type is
      reverseMiddleSection: slice_End_Type;
      lastIndex:Integer := otherWayBinary'Last;
   begin
      for i in otherWayBinary'range loop
         reverseMiddleSection(lastIndex) := otherWayBinary(i);
         lastIndex := lastIndex - 1;
      end loop;
      return reverseMiddleSection;
   end reverseEndSlice;

   -- reverses the binary for entire
   function reverseAllBinary(rightWayBitStr: BitString) return BitString is
      reversedBinary: BitString;
      lastIndex: Integer := rightWayBitStr'Last;

   begin
      for i in rightWayBitStr'range  loop
         reversedBinary(lastIndex) := rightWayBitStr(i);
         lastIndex := lastIndex - 1;
      end loop;
      return reversedBinary;
   end reverseAllBinary;

   -- checks to see if the middle slice contains all zeros
   function SigBit(midSlice: slice_Middle_Type) return boolean is
      containAOne: Boolean := false;
   begin
      for i in reverse midSlice'Range loop
         if midSlice(i) = 1 then
            containAOne := true;
            exit;
         end if;
      end loop;
      return containAOne;
   end SigBit;
   -- prints the hidden bit
   function printHiddenBit(midSlice: slice_Middle_Type; floatNum: Float)
                           return Integer is
      oneOrZero: Integer := 0;
   begin
       if SigBit(midSlice) then
            oneOrZero := 1;
       elsif SigBit(midSlice) then
            oneOrZero := 0;
       end if;
       return oneOrZero;
   end printHiddenBit;

   -- prints the middle column
   procedure printMiddleNum(bitStr: BitString) is
      outputInt:Integer;
   begin
      if bitStr(bitStr'Length - 1) = 1 then
         put("-");
         put(printHiddenBit(retNewMiddleSlice(bitStr),back_to_float(bitStr)),0);
      else
          put(printHiddenBit(retNewMiddleSlice(bitStr),back_to_float(bitStr)),2);
      end if;
      put(".");
      print(retNewEndSlice(bitStr));
      if back_to_float(bitStr) = 0.0 or back_to_float(bitStr) = -0.0 then
         outputInt := 0;
      else
         outputInt := calculateExpoNum(retNewMiddleSlice(bitStr));
      end if;
      put("E");
      put(outputInt , 4);
   end  printMiddleNum;

   -- rebuild the binary string for both slices reversed
   procedure rebuildBinary(originalBitArray: in out BitString) is
      middleSlice: slice_Middle_Type := retNewMiddleSlice(originalBitArray);
      revMiddleSlice: slice_Middle_Type := reverseMiddleSlice(middleSlice);
      endSlice: slice_End_Type := retNewEndSlice(originalBitArray);
      revEndSlice: slice_End_Type := reverseEndSlice(endSlice);
   begin
      for i in reverse originalBitArray'Range loop
         if i in revEndSlice'Range then
            originalBitArray(i) := revEndSlice(i);
         elsif i in revMiddleSlice'range then
               originalBitArray(i) := revMiddleSlice(i);
         end if;
      end loop;
   end rebuildBinary;

   -- prints the special cases
   procedure printSpecialCase(floatNum: Float) is
   begin
      if not floatNum'Valid then
         put(floatNum, aft => 29);
      else
         printMiddleNum(copy_bits(floatNum));
      end if;
   end printSpecialCase;

   numFromFile: Float;
   secondLineFloat: Float;
   thirdLineFloat: Float;
   b: BitString;

begin
   while not End_Of_File loop
      get(numFromFile);
      put(numFromFile, aft => 8);
      put("   ");
      b := copy_bits(numFromFile);
      printSpecialCase(numFromFile);
      put("   ");
      printFormattedBinary(b); New_Line;
      secondLineFloat := back_to_float(reverseAllBinary(b));
      put(secondLineFloat, aft => 8);
      put("   ");
      printSpecialCase(secondLineFloat);
      put("   ");
      printFormattedBinary(copy_bits(secondLineFloat));
      rebuildBinary(b);
      thirdLineFloat := back_to_float(b);
      New_Line;
      put(thirdLineFloat, aft => 8);
      put("   ");
      printSpecialCase(thirdLineFloat);
      put("   ");
      printFormattedBinary(b);
      New_Line;
      put("------------------------------------------------------------------");
      put("--------------------------------");
      New_Line;
   end loop;
exception
   when End_Error => Put_Line("reached the end of file!!");
   when Data_Error => Put_Line("non-numeric number found!!");
end floatflip;
