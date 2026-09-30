export default async ({ project }) => {
 const p=await project({dir:"/tmp/severence/edit",size:"1920x1080",fps:30,background:"#05091d"});
 const logo=await p.add("/tmp/severence/logo.png");
 p.compose(<media file={logo} x={510} y={90} width={900} height={900} fit="contain" animate={[{property:"opacity",keyframes:[{at:0,value:0},{at:.5,value:1},{at:2.5,value:1},{at:3,value:0}]}]}/>,{at:0,dur:3,name:"Limiar Studio"});
 const cuts=[[1,3,2],[2,5,3],[3,8,7],[4,15,8],[5,23,8],[6,31,2],[7,33,2],[8,35,2],[9,37,2],[10,39,10],[11,49,7]];
 for(const [i,at,dur] of cuts){const source=await p.add("/tmp/severence/"+i+".mp4");p.cut(source,{from:i===2?1:0,dur,at,fit:"cover"});}
 const title=await p.add("/tmp/severence/title.png");
 p.compose(<media file={title} width={1920} height={1080} x={0} y={0} fit="cover" animate={[{property:"opacity",keyframes:[{at:0,value:0},{at:.35,value:1},{at:3.4,value:1},{at:4,value:0}]}]}/>,{at:56,dur:4,name:"Severence — Ecos do Tempo"});
 await p.render("/tmp/severence/picture.mp4",{depth:8,bitrate:10000000,concurrency:2});
};
