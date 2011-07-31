import flash.Vector;
import flash.Vector;

class Perlin
{
  static inline var gradientSize = 256;
  
  static var _perm = [
    225,155,210,108,175,199,221,144,203,116, 70,213, 69,158, 33,252,
    5, 82,173,133,222,139,174, 27,  9, 71, 90,246, 75,130, 91,191,
    169,138,  2,151,194,235, 81,  7, 25,113,228,159,205,253,134,142,
    248, 65,224,217, 22,121,229, 63, 89,103, 96,104,156, 17,201,129,
     36,  8,165,110,237,117,231, 56,132,211,152, 20,181,111,239,218,
    170,163, 51,172,157, 47, 80,212,176,250, 87, 49, 99,242,136,189,
    162,115, 44, 43,124, 94,150, 16,141,247, 32, 10,198,223,255, 72,
     53,131, 84, 57,220,197, 58, 50,208, 11,241, 28,  3,192, 62,202,
     18,215,153, 24, 76, 41, 15,179, 39, 46, 55,  6,128,167, 23,188,
    106, 34,187,140,164, 73,112,182,244,195,227, 13, 35, 77,196,185,
     26,200,226,119, 31,123,168,125,249, 68,183,230,177,135,160,180,
     12,  1,243,148,102,166, 38,238,251, 37,240,126, 64, 74,161, 40,
    184,149,171,178,101, 66, 29, 59,146, 61,254,107, 42, 86,154,  4,
    236,232,120, 21,233,209, 45, 98,193,114, 78, 19,206, 14,118,127,
     48, 79,147, 85, 30,207,219, 54, 88,234,190,122, 95, 67,143,109,
    137,214,145, 93, 92,100,245,  0,216,186, 60, 83,105, 97,204, 52];

  var perm:Vector<Int>;
  
  var size:Float;
  var width:Int;
  var height:Int;
  
  var loop:Int;
  
  var gradients:Vector<Float>;
  var memo:Array<Vector<Float>>;

  public function new(_size, _width,_height, _loop=1000) {
    size   = _size;
    width  = _width;
    height = _height;
    
    loop = _loop;
    
    gradients = new Vector((gradientSize+1)*3,true);
    initGradients();
    
    perm = Vector.ofArray(_perm); perm.fixed = true;
    
    memo = new Array();
  }

  function initGradients() {
    for (i in 0 ... gradientSize) {
      var z = 1 - 2 * Math.random();
      var r = Math.sqrt(1 - z*z);
      var theta = 2 * Math.PI * Math.random();
      gradients[i*3]   = r * Math.cos(theta);
      gradients[i*3+1] = r * Math.sin(theta);
      gradients[i*3+2] = z;
    }
  }
  
  var buf :Vector<Float>;
  var buf2:Vector<Float>;
  
  public function prep(iz) {
    var out = new Vector<Float>((width+1)*(height+1)*4, true);
    
    var i = 0;
    
    for(y in 0 ... height+1)
    for(x in 0 ... width+1) {
      noise2(x/size,y/size, iz, out,i);
      i += 4;
    }
    
    return memo[iz] = out;
  }

  inline function noise2(x,y, iz, out:Vector<Float>,i) {
    var ix = Std.int(x), fx0 = x-ix, fx1 = fx0-1, wx = smooth(fx0);
    var iy = Std.int(y), fy0 = y-iy, fy1 = fy0-1, wy = smooth(fy0);
    
    out[i]   = lattice2(ix,   iy,   iz, fx0,fy0);
    out[i+1] = lattice2(ix+1, iy,   iz, fx1,fy0);
    out[i+2] = lattice2(ix,   iy+1, iz, fx0,fy1);
    out[i+3] = lattice2(ix+1, iy+1, iz, fx1,fy1);
  }

  public function render(z:Float) {
    var iz  = Std.int(z) % loop;
    var iz1 = (iz+1) % loop;
    
    buf = memo[iz];
    buf2 = memo[iz1];
    
    if(buf == null)  buf  = prep(iz);
    if(buf2 == null) buf2 = prep(iz1);
    
    var out = new Vector(width*height*4,true);
    var oi = 0;
    
    var i = 0;
    
    for(y in 0 ... height) {
      for(x in 0 ... width) {
        out[oi++] = noise(x/size,y/size, z, i);
        i += 4;
      }
      
      i += 4;
    }
    
    return out;
  }

  inline function noise(x:Float,y:Float,z:Float, i) {
    var ix = Std.int(x), iy = Std.int(y), iz = Std.int(z);
    
    var fx0 = x-ix, fx1 = fx0-1, wx = smooth(fx0);
    var fy0 = y-iy, fy1 = fy0-1, wy = smooth(fy0);
    var fz0 = z-iz, fz1 = fz0-1, wz = smooth(fz0);
    
    return
    lerp(wz,
      lerp(wy,
        lerp(wx,
          latticeZ(ix,  iy,iz, buf[i], fz0),
          latticeZ(ix+1,iy,iz, buf[i+1], fz0)),
        lerp(wx,
          latticeZ(ix,  iy+1,iz, buf[i+2], fz0),
          latticeZ(ix+1,iy+1,iz, buf[i+3], fz0))
      ),
      lerp(wy,
        lerp(wx,
          latticeZ(ix,  iy,iz+1, buf2[i], fz1),
          latticeZ(ix+1,iy,iz+1, buf2[i+1], fz1)),
        lerp(wx,
          latticeZ(ix,  iy+1,iz+1, buf2[i+2], fz1),
          latticeZ(ix+1,iy+1,iz+1, buf2[i+3], fz1))
      ));
  }
  
  inline function lattice2(ix,iy,iz, fx:Float,fy:Float) {
    var g = index(ix,iy,iz) * 3;
    return gradients[g] * fx + gradients[g+1] * fy;
  }

  inline function latticeZ(ix,iy,iz, base:Float, fz:Float) {
    var g = index(ix,iy,iz) * 3;
    return base + gradients[g+2] * fz;
  }
  
  /*inline function lattice(ix,iy,iz, fx:Float,fy:Float,fz:Float) {
    var g = index(ix,iy,iz) * 3;
    return gradients[g] * fx + gradients[g+1] * fy + gradients[g+2] * fz;
  }*/
  
  inline function permutate(x) { return perm[x & (gradientSize-1)]; }

  inline function index(ix,iy,iz) {
    return permutate(ix + permutate(iy + permutate(iz)));
  }
  
  inline function lerp(t:Float, a:Float,b:Float) {
    return a + t * (b-a);
  }
  
  inline function smooth(x:Float) {
    return x * x * (3 - 2 * x);
  }
}
