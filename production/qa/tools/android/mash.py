import sys
# mash.py X Y N [interval] [hold] -> fastmt script of N taps
x,y,n=sys.argv[1],sys.argv[2],int(sys.argv[3]); iv=float(sys.argv[4]) if len(sys.argv)>4 else 0.35; h=float(sys.argv[5]) if len(sys.argv)>5 else 0.06
print('; '.join(f'down 0 {x} {y}; wait {h}; up 0; wait {iv-h:.3f}' for _ in range(n)))
