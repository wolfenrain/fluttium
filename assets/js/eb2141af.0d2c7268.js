"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[959],{3905:(t,e,n)=>{n.d(e,{Zo:()=>l,kt:()=>d});var r=n(7294);function i(t,e,n){return e in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function o(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable}))),n.push.apply(n,r)}return n}function a(t){for(var e=1;e<arguments.length;e++){var n=null!=arguments[e]?arguments[e]:{};e%2?o(Object(n),!0).forEach((function(e){i(t,e,n[e])})):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(e){Object.defineProperty(t,e,Object.getOwnPropertyDescriptor(n,e))}))}return t}function c(t,e){if(null==t)return{};var n,r,i=function(t,e){if(null==t)return{};var n,r,i={},o=Object.keys(t);for(r=0;r<o.length;r++)n=o[r],e.indexOf(n)>=0||(i[n]=t[n]);return i}(t,e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(t);for(r=0;r<o.length;r++)n=o[r],e.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(t,n)&&(i[n]=t[n])}return i}var p=r.createContext({}),s=function(t){var e=r.useContext(p),n=e;return t&&(n="function"==typeof t?t(e):a(a({},e),t)),n},l=function(t){var e=s(t.components);return r.createElement(p.Provider,{value:e},t.children)},u={inlineCode:"code",wrapper:function(t){var e=t.children;return r.createElement(r.Fragment,{},e)}},f=r.forwardRef((function(t,e){var n=t.components,i=t.mdxType,o=t.originalType,p=t.parentName,l=c(t,["components","mdxType","originalType","parentName"]),f=s(n),d=i,m=f["".concat(p,".").concat(d)]||f[d]||u[d]||o;return n?r.createElement(m,a(a({ref:e},l),{},{components:n})):r.createElement(m,a({ref:e},l))}));function d(t,e){var n=arguments,i=e&&e.mdxType;if("string"==typeof t||i){var o=n.length,a=new Array(o);a[0]=f;var c={};for(var p in e)hasOwnProperty.call(e,p)&&(c[p]=e[p]);c.originalType=t,c.mdxType="string"==typeof t?t:i,a[1]=c;for(var s=2;s<o;s++)a[s]=n[s];return r.createElement.apply(null,a)}return r.createElement.apply(null,n)}f.displayName="MDXCreateElement"},1118:(t,e,n)=>{n.r(e),n.d(e,{assets:()=>p,contentTitle:()=>a,default:()=>u,frontMatter:()=>o,metadata:()=>c,toc:()=>s});var r=n(7462),i=(n(7294),n(3905));const o={sidebar_position:3,description:"The capabilities of the text input action."},a="Text Input",c={unversionedId:"actions/input-text",id:"actions/input-text",title:"Text Input",description:"The capabilities of the text input action.",source:"@site/docs/actions/input-text.md",sourceDirName:"actions",slug:"/actions/input-text",permalink:"/docs/actions/input-text",draft:!1,editUrl:"https://github.com/wolfenrain/docs/tree/main/docs/docs/actions/input-text.md",tags:[],version:"current",sidebarPosition:3,frontMatter:{sidebar_position:3,description:"The capabilities of the text input action."},sidebar:"tutorialSidebar",previous:{title:"Expectations",permalink:"/docs/actions/expectations"}},p={},s=[{value:"Writing text",id:"writing-text",level:2},{value:"Erasing text",id:"erasing-text",level:2}],l={toc:s};function u(t){let{components:e,...n}=t;return(0,i.kt)("wrapper",(0,r.Z)({},l,n,{components:e,mdxType:"MDXLayout"}),(0,i.kt)("h1",{id:"text-input"},"Text Input"),(0,i.kt)("p",null,"Fluttium provides a set of actions that will allow you to input values into the widgets of your\napplication."),(0,i.kt)("h2",{id:"writing-text"},"Writing text"),(0,i.kt)("p",null,"Write text, regardless of focus, automatically using the ",(0,i.kt)("inlineCode",{parentName:"p"},"inputText")," action. The full YAML syntax\nof this action is as followed:"),(0,i.kt)("pre",null,(0,i.kt)("code",{parentName:"pre",className:"language-yaml"},"- inputText: 'Your Text'\n")),(0,i.kt)("h2",{id:"erasing-text"},"Erasing text"),(0,i.kt)("admonition",{type:"info"},(0,i.kt)("p",{parentName:"admonition"},"This is not yet implemented.")))}u.isMDXComponent=!0}}]);