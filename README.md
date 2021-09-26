# Preprocessing Module

This project consists of a language-independent pre-processor that is programmable in Racket.  Similar to other pre-processors this script reads input files (in.txt) and writes the result on output files (out.txt).

The preprocessor looks for active tokens, which are just a sequence of characters that trigger an action. Bellow are listed the available active tokens and their functions.

## Local Type Inference
Local type inference allows for simpler variable declarations. 

**Example:** 
```
var x = new  Kitten();
```
Gets replaced by:
```
Kitten x = new  Kitten();
```
Here, the active token is the keyword **var** and it looks for variable declarations that are immediately initialized with a constructor call (an expression that starts with the new keyword).

## String Interpolation
String interpolation is a useful feature that is not present in every language that allows expressions in the middle of the string definition. 

**Example:**
```
"A #{boy} loves #{h*s} dog."
```
Becomes:
```
"A "+(boy)+" loves "+(h*s)+" dog."
```

## Type Aliasing
Similar to typedef in C, Type Aliasing allows the assign of alternative names to existing datatypes.

**Example:**
```
alias x = Vault;
x  myX = new  x();
```
Becomes:
```
Vault  myX = new  Vault();
```

## Setters and Getters
By the use of the token **$SG**, instead of the modifier when defining a new variable, the preprocesser makes the variable private and creates its getter and setter.

**Example:**
```
$SG  int  x;
```   
Turns into:
```
private int x;
public void setX(int aux) { x = aux; }
public getX(){ return x; }
```
Running the script with the example found in A.in the input and output are as follows:

**INPUT:**
```
alias a0 = "#{args[0]}";
public class Foo {
	$SG int i;
	alias display = System.out.println;
    public void foo(String[] args) {
    	display(#a0);
    }
}
``` 

**OUTPUT:**
```

public class Foo {
	private int i;
	public void setI(int aux){ this.i = aux; }
	public getI(){ return this.i; }
	
    public void foo(String[] args) {
    	 System.out.println( "" + (args[0]) + "");
    }
}
```