package com.stratoscreen.utils
{
	/*This class has two function 
	*converts strings representing base 62 numbers to decimal numbers and
	*converts numbers to strings representing a base 62 system
	*
	*Currently because of the errors inherent with floating points toString only works with integers
	*
	*The base 62 system uses characters representing the following values:
	*base62 : base10 (Decimal)
	*0-9 : 0-9
	*A-Z : 10-35
	*a-z : 36-61
	*
	*for more debate on the concept and similar concepts see this thread:
	*  http://www.kirupa.com/forum/showthread.php?t=351816
	*
	*
	* created on 25th/July/2010
	* www.shaedo.com
	*/
	
	public class Base62
	{
		private static var _sa:Array;
		
		public function Base62()
		{
		}
		
		public function toNumber(s:String):Number
		{
			var n:Number=0;// values are added to this as they are converted from string to numbers
			var a:Array=s.split('.'); // splits if there is a 'decimal' place
			var b:String=a[0];// characters representing values greater than 1
			var i:int;//counter
			var j:int;//counter
			var l:String;//used for individual character from 'a'
			var c:int;//the non-positional int value for each character
			
			for(i=0,j=b.length;i<j;i++)
			{
				l=b.slice(i,i+1);//Get the next character in the string
				c=parseInt(l,36);//convert to int
				if(l.charCodeAt()>96)c+=26;//if lower case add 26
				n+=c*Math.pow(62,(b.length-i-1));//scale number by its position and add to total
			}
			if(a.length>1)//if there is a 'decimal' point...
			{
				var m:Number=0;//used to create number that is then adjusted to be below the decimal point
				b=a[1];// characters representing values less than 1/ below the 'decimal' point
				for(i=0,j=b.length;i<j;i++)
				{
					l=b.slice(i,i+1);//Get the next character in the string
					c=parseInt(l,36);//convert to int
					if(l.charCodeAt()>96)c+=26;//if lower case add 26
					m+=c*Math.pow(62,(b.length-i-1));//scale number by its position and add to total
				}
				m=m/Math.pow(10,(String(m).length));//convert to decimal
				n+=m;//add decimal values to integer value
			}
			return(n);
		}
		public function toString(n:Number):String
		{
			var s:String='';//string that has values added to it
			var c:int=n;//current value this is decreased as it is progresively divided by 62 and the remainder converted to the corresponding character
			var r:int;//this is the remainder of c/62 and corresponds to the position in 'sa' which represents the character for the base62		
			if(_sa == null)_sa=new Array('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z');
			while(c>0)
			{
				r=c%62;
				s=_sa[r]+s;
				c=c/62;
			}
			return(s);
		}
		
	}
}