import { HashMap } from "@kit.ArkTS";


export default  class HostOption{
   static readonly REQUEST_AUDIOFOCUS = "request-audio-focus";
   static readonly RELEASE_AUDIOFOCUS = "release-audio-focus";
   static readonly REQUEST_SCREENON = "request-screen-on";
   static readonly ENABLE_SNAPSHOT = "enable-snapshot";

   private mNumberOption:HashMap<string,number> = new HashMap();
   private mStrOption:HashMap<string,string> = new HashMap();

   addNumberOption(key:string,value:number){
      this.mNumberOption.set(key,value);
   }

   addStrOption(key:string,value:string){
      this.mStrOption.set(key,value);
   }

   getNumberOption(key:string,defaultValue:number):number{
      if(this.mNumberOption.hasKey(key)){
         return this.mNumberOption.get(key);
      }
      return defaultValue;
   }

   getStrOption(key:string,defaultValue:string):string{
      if(this.mStrOption.hasKey(key)){
         return this.mStrOption.get(key);
      }
      return defaultValue;
   }

}