"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[870],{3905:(t,e,n)=>{n.d(e,{Zo:()=>u,kt:()=>d});var r=n(7294);function o(t,e,n){return e in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function a(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable}))),n.push.apply(n,r)}return n}function i(t){for(var e=1;e<arguments.length;e++){var n=null!=arguments[e]?arguments[e]:{};e%2?a(Object(n),!0).forEach((function(e){o(t,e,n[e])})):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):a(Object(n)).forEach((function(e){Object.defineProperty(t,e,Object.getOwnPropertyDescriptor(n,e))}))}return t}function l(t,e){if(null==t)return{};var n,r,o=function(t,e){if(null==t)return{};var n,r,o={},a=Object.keys(t);for(r=0;r<a.length;r++)n=a[r],e.indexOf(n)>=0||(o[n]=t[n]);return o}(t,e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(t);for(r=0;r<a.length;r++)n=a[r],e.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(t,n)&&(o[n]=t[n])}return o}var s=r.createContext({}),c=function(t){var e=r.useContext(s),n=e;return t&&(n="function"==typeof t?t(e):i(i({},e),t)),n},u=function(t){var e=c(t.components);return r.createElement(s.Provider,{value:e},t.children)},f={inlineCode:"code",wrapper:function(t){var e=t.children;return r.createElement(r.Fragment,{},e)}},p=r.forwardRef((function(t,e){var n=t.components,o=t.mdxType,a=t.originalType,s=t.parentName,u=l(t,["components","mdxType","originalType","parentName"]),p=c(n),d=o,m=p["".concat(s,".").concat(d)]||p[d]||f[d]||a;return n?r.createElement(m,i(i({ref:e},u),{},{components:n})):r.createElement(m,i({ref:e},u))}));function d(t,e){var n=arguments,o=e&&e.mdxType;if("string"==typeof t||o){var a=n.length,i=new Array(a);i[0]=p;var l={};for(var s in e)hasOwnProperty.call(e,s)&&(l[s]=e[s]);l.originalType=t,l.mdxType="string"==typeof t?t:o,i[1]=l;for(var c=2;c<a;c++)i[c]=n[c];return r.createElement.apply(null,i)}return r.createElement.apply(null,n)}p.displayName="MDXCreateElement"},1704:(t,e,n)=>{n.r(e),n.d(e,{assets:()=>s,contentTitle:()=>i,default:()=>f,frontMatter:()=>a,metadata:()=>l,toc:()=>c});var r=n(7462),o=(n(7294),n(3905));const a={sidebar_position:4},i="\ud83e\uddea Testing A Flow Test",l={unversionedId:"getting-started/testing-a-first-flow-test",id:"getting-started/testing-a-first-flow-test",title:"\ud83e\uddea Testing A Flow Test",description:"Testing a flow can be done through the fluttium test command. This command will read the",source:"@site/docs/getting-started/testing-a-first-flow-test.md",sourceDirName:"getting-started",slug:"/getting-started/testing-a-first-flow-test",permalink:"/docs/getting-started/testing-a-first-flow-test",draft:!1,editUrl:"https://github.com/wolfenrain/fluttium/tree/main/docs/docs/getting-started/testing-a-first-flow-test.md",tags:[],version:"current",sidebarPosition:4,frontMatter:{sidebar_position:4},sidebar:"tutorialSidebar",previous:{title:"\ud83e\ude84 Creating A Flow Test",permalink:"/docs/getting-started/creating-a-flow-test"},next:{title:"\ud83d\udca5 Actions",permalink:"/docs/actions"}},s={},c=[{value:"Watching flow tests",id:"watching-flow-tests",level:2}],u={toc:c};function f(t){let{components:e,...n}=t;return(0,o.kt)("wrapper",(0,r.Z)({},u,n,{components:e,mdxType:"MDXLayout"}),(0,o.kt)("h1",{id:"-testing-a-flow-test"},"\ud83e\uddea Testing A Flow Test"),(0,o.kt)("p",null,"Testing a flow can be done through the ",(0,o.kt)("inlineCode",{parentName:"p"},"fluttium test")," command. This command will read the\n",(0,o.kt)("inlineCode",{parentName:"p"},"fluttium.yaml")," file, apply any of the configuration it has to the driver, and run the given flow\nfile."),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-shell"},"fluttium test my_flow.yaml\n")),(0,o.kt)("p",null,"The output of this command reflects the success state of the user flow. Each step will be executed, and if one step fails, it will stop executing steps and indicate which step failed with a potential\nreason."),(0,o.kt)("h2",{id:"watching-flow-tests"},"Watching flow tests"),(0,o.kt)("p",null,"Fluttium can also watch for any changes to either the flow file or the Flutter project, allowing\nus to hot reload whenever changes are detected:"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-shell"},"fluttium test my_flow.yaml --watch\n")),(0,o.kt)("p",null,"The ",(0,o.kt)("inlineCode",{parentName:"p"},"fluttium test")," command has options to override settings in the ",(0,o.kt)("inlineCode",{parentName:"p"},"fluttium.yaml")," file. For the\nfull overview of options run:"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-shell"},"fluttium test --help\n")))}f.isMDXComponent=!0}}]);