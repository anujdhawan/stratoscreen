package com.stratoscreen.managers
{
	import com.stratoscreen.components.Fade_;
	import com.stratoscreen.components.Parallel_;
	
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.events.EffectEvent;
	
	import spark.effects.Fade;
	import spark.effects.Move;
	import spark.effects.Rotate;

	public class EffectsManager
	{
		public static const EFFECT_NONE:String = "0";
		public static const EFFECT_FADE:String = "1";
		public static const EFFECT_SPIN:String = "2";
		public static const EFFECT_SLIDE:String = "3";
		
		private static const _effectsList:Array = new Array({value: EFFECT_NONE, label: "None"}, 
			                                                {value: EFFECT_FADE, label: "Fade"}, 
															{value: EFFECT_SPIN, label: "Spin"},
															{value: EFFECT_SLIDE, label: "Slide"});
		
		public static function get effectsList():ArrayCollection
		{
			return new ArrayCollection(_effectsList);;
		}
		
		public function EffectsManager()
		{
		}
		
		public function fadeIn(callback:Function = null, alphaFrom:Number = 0, alphaTo:Number = 1, duration:Number = 500 ):Fade_
		{			
			return createFade(callback, alphaFrom, alphaTo, duration);
		}
		
		public function fadeOut(callback:Function = null, alphaFrom:Number = 1, alphaTo:Number = 0, duration:Number = 500 ):Fade_
		{			
			return createFade(callback, alphaFrom, alphaTo, duration);
		}
		
		public function spinIn(callback:Function = null, angleFrom:Number = 90, angleTo:Number = 0, alphaFrom:Number = 0, alphaTo:Number = 1, duration:Number = 500 ):Parallel_
		{
			return createSpin(callback, angleFrom, angleTo, alphaFrom, alphaTo, duration);
		}

		public function spinOut(callback:Function = null, angleFrom:Number = 0, angleTo:Number = 90,  alphaFrom:Number = 1, alphaTo:Number = 0, duration:Number = 500 ):Parallel_
		{
			return createSpin(callback, angleFrom, angleTo, alphaFrom, alphaTo, duration);
		}

		public function slideIn(callback:Function = null, xFrom:Number = -2000, xTo:Number = 0, alphaFrom:Number = 0, alphaTo:Number = 1, duration:Number = 500 ):Parallel_
		{
			return createSlide(callback, xFrom, xTo, alphaFrom, alphaTo, duration);
		}

		public function slideOut(callback:Function = null, xFrom:Number = 0, xTo:Number = -2000, alphaFrom:Number = 1, alphaTo:Number = 0, duration:Number = 500 ):Parallel_
		{
			return createSlide(callback, xFrom, xTo, alphaFrom, alphaTo, duration);
		}

		private function createFade(callback:Function, alphaFrom:Number, alphaTo:Number, duration:Number):Fade_
		{			
			var fade:Fade_ = new Fade_();
			fade.alphaFrom = alphaFrom;
			fade.alphaTo = alphaTo;
			fade.duration = duration;
			fade.callback = callback;
			fade.addEventListener(EffectEvent.EFFECT_END, effectEndHandler);
			
			return fade;
		}
		
		private function createSpin(callback:Function, angleFrom:Number, angleTo:Number, alphaFrom:Number, alphaTo:Number, duration:Number):Parallel_
		{
			var base:Parallel_ = new Parallel_();
			base.callback = callback;
			base.addEventListener(EffectEvent.EFFECT_END, effectEndHandler);
			
			var fade:Fade = new Fade();
			fade.alphaFrom = alphaFrom;
			fade.alphaTo = alphaTo;
			fade.duration = duration;
			base.addChild(fade);
				
			var rotate:Rotate = new Rotate();
			rotate.angleFrom = angleFrom;
			rotate.angleTo = angleTo;
			rotate.duration = duration;
			base.addChild(rotate);
			

			return base;
		}

		private function createSlide(callback:Function, xFrom:Number, xTo:Number, alphaFrom:Number, alphaTo:Number, duration:Number):Parallel_
		{
			var base:Parallel_ = new Parallel_();
			base.callback = callback;
			base.addEventListener(EffectEvent.EFFECT_END, effectEndHandler);

			var fade:Fade = new Fade();
			fade.alphaFrom = alphaFrom;
			fade.alphaTo = alphaTo;
			fade.duration = duration;
			base.addChild(fade);
			
			var move:Move = new Move();
			move.xFrom = xFrom;
			move.xTo = xTo;
			move.duration = duration;
			base.addChild(move);
						
			return base;
		}
		
		private function effectEndHandler(event:Event):void
		{
			event.target.removeEventListener(EffectEvent.EFFECT_END, effectEndHandler);
			if (event.target.callback != null) 
			{
				event.target.callback(event);
			}
			
		}
	}
}