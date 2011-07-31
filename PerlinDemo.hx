// haxe -main PerlinDemo -swf perlin.swf -swf-header 600:600:0x666666:50

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.Lib;
import flash.Vector;

class PerlinDemo {
  static function main() {
    var root = Lib.current;
    
    var bm = new BitmapData(width,height,true);
    
    var b = new Bitmap(bm);
    b.scaleX = b.scaleY = 2;
    root.addChild(b);
    
    var perlin = new Perlin(12, width+1,height+1, 5);
    
    b.filters = [new flash.filters.BlurFilter(2,2,2)];  
    var x = new Caustics(60);
    
    //var x = new Display();
    
    var out = new Vector<UInt>(width*height, true);
    
    var t = 0.;
    root.addEventListener('enterFrame', function(_) {
      t = (t+.05) % 5;
      
      x.calc(perlin.render(t), out);
      
      bm.setVector(bm.rect, out);
    });
  }
  
  public static inline var width  = 150;
  public static inline var height = 150;
}

class Display {
  public function new() {}
  
  public function calc(buf:Vector<Float>,out:Vector<UInt>) {
    var width  = PerlinDemo.width;
    var height = PerlinDemo.height;
    
    for(x in 0 ... width)
    for(y in 0 ... height) {
      var v = buf[pos(width+1, x,  y)];
      
      out[pos(width, x,y)] = Std.int((v+.7)/1.4*255);
    }
    
    for(i in 0 ... cast out.length) {
      var c = out[i];
      out[i] = c << 24 | 0x9999ff;
    }
  }
  
  static inline function pos(w,x,y) { return y*w+x; }
}

class Caustics {
  var depth:Float;
  
  public function new(depth) {
    this.depth = depth;
  }
  
  public function calc(buf:Vector<Float>,out:Vector<UInt>) {
    var width  = PerlinDemo.width;
    var height = PerlinDemo.height;
    
    for(i in 0 ... out.length) out[i] = 0;
    
    for(x in 0 ... width)
    for(y in 0 ... height) {
      var a = buf[pos(width+1, x,  y)],
          b = buf[pos(width+1, x+1,y)],
          c = buf[pos(width+1, x,  y+1)];
      
      var px = x + Std.int((a-b)*depth);
      var py = y + Std.int((a-c)*depth);
      
      var p = pos(width, px,py);
      if(p>0 &&  p<width*height) out[p]++;
    }
    
    for(i in 0 ... cast out.length) {
      var c = switch(out[i])
        { case 0: 0; case 1: 0x1a; case 2: 0x66; case 3: 0x88; case 4: 0xcc; default: 0xff; }
      out[i] = c << 24 | 0x9999ff;
    }
  }
  
  static inline function pos(w,x,y) { return y*w+x; }
}
