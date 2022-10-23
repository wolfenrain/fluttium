"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[43],{3905:(e,t,n)=>{n.d(t,{Zo:()=>p,kt:()=>f});var r=n(7294);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function a(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function s(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var c=r.createContext({}),l=function(e){var t=r.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):a(a({},t),e)),n},p=function(e){var t=l(e.components);return r.createElement(c.Provider,{value:t},e.children)},u={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},d=r.forwardRef((function(e,t){var n=e.components,o=e.mdxType,i=e.originalType,c=e.parentName,p=s(e,["components","mdxType","originalType","parentName"]),d=l(n),f=o,m=d["".concat(c,".").concat(f)]||d[f]||u[f]||i;return n?r.createElement(m,a(a({ref:t},p),{},{components:n})):r.createElement(m,a({ref:t},p))}));function f(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var i=n.length,a=new Array(i);a[0]=d;var s={};for(var c in t)hasOwnProperty.call(t,c)&&(s[c]=t[c]);s.originalType=e,s.mdxType="string"==typeof e?e:o,a[1]=s;for(var l=2;l<i;l++)a[l]=n[l];return r.createElement.apply(null,a)}return r.createElement.apply(null,n)}d.displayName="MDXCreateElement"},3987:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>c,contentTitle:()=>a,default:()=>u,frontMatter:()=>i,metadata:()=>s,toc:()=>l});var r=n(7462),o=(n(7294),n(3905));const i={sidebar_position:1,description:"The different gesture actions."},a="Gestures",s={unversionedId:"actions/gestures",id:"actions/gestures",title:"Gestures",description:"The different gesture actions.",source:"@site/docs/actions/gestures.md",sourceDirName:"actions",slug:"/actions/gestures",permalink:"/docs/actions/gestures",draft:!1,editUrl:"https://github.com/wolfenrain/docs/tree/main/docs/docs/actions/gestures.md",tags:[],version:"current",sidebarPosition:1,frontMatter:{sidebar_position:1,description:"The different gesture actions."},sidebar:"tutorialSidebar",previous:{title:"Actions",permalink:"/docs/actions"},next:{title:"Expectations",permalink:"/docs/actions/expectations"}},c={},l=[{value:"Tapping",id:"tapping",level:2},{value:"Long press",id:"long-press",level:2},{value:"Drag gestures",id:"drag-gestures",level:2}],p={toc:l};function u(e){let{components:t,...n}=e;return(0,o.kt)("wrapper",(0,r.Z)({},p,n,{components:t,mdxType:"MDXLayout"}),(0,o.kt)("h1",{id:"gestures"},"Gestures"),(0,o.kt)("p",null,"Fluttium provides a set of actions that will allow you to execute certain gesture in your\napplication."),(0,o.kt)("h2",{id:"tapping"},"Tapping"),(0,o.kt)("p",null,"To tap on widgets in your application you can use the ",(0,o.kt)("inlineCode",{parentName:"p"},"tapOn")," action. The full YAML syntax of this\naction is as followed:"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-yaml"},"- tapOn:\n    text: 'Your Text' # An optional text regexp that is used to find a widget by semantic labels and visible text\n")),(0,o.kt)("p",null,"The short-hand syntax for this action is:"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-yaml"},"- tapOn: 'Your Text' # It will try to find by semantic labels and visible text\n")),(0,o.kt)("h2",{id:"long-press"},"Long press"),(0,o.kt)("admonition",{type:"info"},(0,o.kt)("p",{parentName:"admonition"},"This is not yet implemented.")),(0,o.kt)("h2",{id:"drag-gestures"},"Drag gestures"),(0,o.kt)("admonition",{type:"info"},(0,o.kt)("p",{parentName:"admonition"},"This is not yet implemented.")))}u.isMDXComponent=!0}}]);