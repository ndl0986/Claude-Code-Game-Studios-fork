# rn <mp4> [scale]: pause dim / night transitions, then (last resume frame -> first night frame) in wall s and game s (wall*scale)
rn(){ local R=$(python3 -c "K,OX,OY=1.28055,448.5,74
r=lambda x,y,w,h: f'{round(OX+x*K)},{round(OY+y*K)},{round(w*K)},{round(h*K)}'
print(';'.join([r(640,620,10,10), r(640,190,8,8)]))"); ./frames probe $1 "$R" | awk -v sc=${2:-0.1} '{split($2,g,","); split($3,s,","); st=(g[1]<150?"DIM":"lit")" "((s[3]>s[1]+20&&s[1]<120)?"night":"day"); if(st!=p){printf "%.3f %s\n",$1/1000,st; if(p ~ /^DIM/ && st ~ /^lit/) r=$1/1000; if(st ~ /night/ && !n){n=$1/1000}; p=st}} END{printf "  last resume frame %.3f -> night %.3f = %.3f s wall = %.4f s game\n", r, n, n-r, (n-r)*sc}'; }
