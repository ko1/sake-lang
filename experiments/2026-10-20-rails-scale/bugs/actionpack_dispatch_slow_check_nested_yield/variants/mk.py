import sys,shutil
D='/home/ko1/app/sake/experiments/2026-10-20-rails-scale/bugs/actionpack_dispatch_slow_check_nested_yield'
fast=open(D+'/fast/actionpack/action_dispatch/routing/mapper.sake').read()
def cutout(t,a,b): i=t.index(a); j=t.index(b,i); return i,j
name=sys.argv[1]; which=sys.argv[2:]
shutil.copytree(D+'/slow', name)
p=name+'/actionpack/action_dispatch/routing/mapper.sake'
s=open(p).read()
def swap(a,sb,fb):
    global s
    i,j=cutout(s,a,sb); fi,fj=cutout(fast,a,fb); s=s[:i]+fast[fi:fj]+s[j:]
for w in which:
    if w=='dm': swap("      def decomposed_match(","      def add_route(","      def add_route(")
    if w=='mm': swap("      def set_member_mappings_for_resource(m)","      # (the fast form's frame functions","      def api_only?(m)")
    if w=='res':
        swap("      # resource :session, only: [...] do ... end","      def collection(m)","      def collection(m)")
        i,j=cutout(s,"      def apply_common_behavior_for(","      def with_scope_level(")
        s=s[:i]+s[j:]
open(p,'w').write(s)
