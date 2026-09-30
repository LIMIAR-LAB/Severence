export default async ({project})=>{
const p=await project({dir:"/tmp/smooth/edit",size:"1920x1080",fps:30});
const base=await p.add("/tmp/smooth/original.mp4");
p.cut(base,{from:0,at:0,dur:60});
for(const [i,at,from,dur] of [[1,5,2,.2],[6,33,2,.2],[7,35,2,.2],[8,37,2,.2],[9,39,2,.3]]){
const h=await p.add("/tmp/smooth/"+i+".mp4");
p.compose(<media file={h} trimStart={from} x={0} y={0} width={1920} height={1080} fit="cover" animate={[{property:"opacity",from:1,to:0,duration:dur,easing:"linear"}]}/>,{at,dur,name:"Dissolve "+i});
}
await p.render("/tmp/smooth/picture.mp4",{depth:8,bitrate:10000000,concurrency:2});
};
