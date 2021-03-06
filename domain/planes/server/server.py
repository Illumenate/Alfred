import sys, os
sys.path.append(".")
try:
	import active2 as active, flyplanes as planes, datetime, display, math, pygame, flygen, flydisplay
except ImportError:
	os.chdir("../")
	sys.path.append(".")
	os.chdir("domain/planes/")
	sys.path.append(".")
	import active2 as active, flyplanes as planes, datetime, display, math, pygame, flygen, flydisplay
from pygame.locals import *
import threading
import sock

host = 'localhost' #change to getHostName or something
port = 5150
if len(sys.argv) < 2:
	raise Exception("Usage: server.py serverFilePath")
try:
	serverFile = open(sys.argv[1], 'w')
except Exception:
	print "failed to open server file for write. Exiting."
	sys.exit()

def create_alf_host_file(f, host, port):
	s = "port " + str(port) + "\n"
	s += "host " + str(host) + "\n"
	s += "process " + str(2887)
	f.write(s)
	f.close()

create_alf_host_file(serverFile, host, port)
	
worldfile = "KB/dd.pl"
#world = flygen.create_random_world()
world = flygen.create_world_from_alf_file(worldfile)

domain = active.Domain(world, active.SimpleActionExecutor())
domain.add_change_rule(planes.flight_arg_select, planes.flight_change_func)
domain.add_change_rule(planes.load_arg_select, planes.load_change_func)
domain.add_change_rule(planes.unload_arg_select, planes.unload_change_func)

screensize = (708, 708)
vis = flydisplay.vis_world(screensize, world)

def plane_chooser(visobjs):
	for obj in visobjs:
		if obj.obj.type == "plane":
			return obj
	return None

def city_chooser(visobjs):
	for obj in visobjs:
		if obj.obj.type == "city":
			return obj
	return None

def package_chooser(visobjs):
	for obj in visobjs:
		if obj.obj.type == "package":
			return obj
	return None

pygame.init()
screen = pygame.display.set_mode(screensize, DOUBLEBUF)

lasttime = datetime.datetime.today()
steps = 0
selectedplane = None
selectedpackage = None
	
serve = sock.Server(host, port)
serviceThread = threading.Thread(target = serve.listen_continuously)
serviceThread.setDaemon(True)
serviceThread.start()

while 1:
	
	cmd = serve.get_cmd()
	if cmd:
		op = None
		args = []
		if cmd[0] not in ["fly", "load", "unload"]:
			#serve.respond("instruction " + cmd[0] + " not recognized. Ignoring.")
			serve.respond("term(af(not_recognized_command(planes)))." + "\n")
		elif cmd[0] == "fly":
			if len(cmd) != 3:
				#serve.respond("fly command requires two args. Got " + str(cmd))
				serve.respond("term(af(fly_requires_two_args(planes)))." + "\n")
			else:
				tmpcmd = cmd[2].split("]")[0]#cmd[2].replace("]", "")
				arg1 = world.get_obj_by_name(cmd[1])
				arg2 = world.get_obj_by_name(tmpcmd)
				valid = True
				if arg1 == None or arg1.type != "plane":
					#serve.respond("plane " + cmd[1] + " not found. Ignoring command" + str(cmd))
					serve.respond("term(af(plane_not_found('" + arg1 + "')))." + "\n")
					valid = False
				if  arg2 == None or arg2.type != "city":
					#serve.respond("city " + cmd[2] + " not found. Ignoring command" + str(cmd))
					serve.respond("term(af(city_not_found('" + tmpcmd + "')))." + "\n")
					valid = False
				if valid:
					op = planes.flyop 
					args = [arg1, arg2]
		elif cmd[0] == "load":
			if len(cmd) != 3:
				#serve.respond("load command requires two args. Got " + str(cmd))
				serve.respond("term(af(load_requires_two_args(planes)))." + "\n")
			else:
				tmpcmd = cmd[2].split("]")[0]
				arg1 = world.get_obj_by_name(cmd[1])
				arg2 = world.get_obj_by_name(tmpcmd)
				valid = True
				if arg1 == None or arg1.type != "package":
					#serve.respond("package " + cmd[1] + " not found. Ignoring command" + str(cmd))
					serve.respond("term(af(package_not_found(planes)))." + "\n")
					valid = False
				if  arg2 == None or arg2.type != "plane":
					#serve.respond("plane " + cmd[2] + " not found. Ignoring command" + str(cmd))
					serve.respond("term(af(plane_not_found('" + tmpcmd + "')))." + "\n")
					valid = False
				if valid:
					op = planes.loadop 
					args = [arg1, arg2]
		elif cmd[0] == "unload":
			if len(cmd) != 2:
				#serve.respond("unload command requires one arg (the package). Got " + str(cmd))
				serve.respond("term(af(unload_requires_one_arg(planes)))." + "\n")
			else:
				tmpcmd = cmd[1].split("]")[0]
				arg1 = world.get_obj_by_name(tmpcmd)
				if arg1 == None or arg1.type != "package":
					#serve.respond("package " + cmd[1] + " not found. Ignoring command" + str(cmd))
					serve.respond("term(af(package_not_found('" + tmpcmd + "')))." + "\n")
				else:
					op = planes.unloadop 
					args = [arg1]
		if op:
			actionValid = domain.add_action(op, args, checkvalid = True)
			if actionValid:
				#serve.respond("ok.")
				serve.respond("term(af(plane_command_sent('" + tmpcmd + "')))." + "\n")
			else:
				#serve.respond("action invalid:" + str(domain.reason_invalid(op, args)))
				serve.respond("term(af(invalid_plane_command(planes)))." + "\n")
	
	screen.blit(vis.draw(), (0, 0))
	pygame.display.flip()
	currenttime = datetime.datetime.today()
	dtime = (currenttime - lasttime).total_seconds()
	domain.update(dtime)
	
	lasttime = currenttime
	steps += 1
	todel = []
	'''
	for time in plantest.planbynames:
		if time <= domain.elapsedtime:
			print time, domain.elapsedtime
			domain.add_action_(plantest.planbynames[time].instantiate(world))
			todel.append(time)
	for time in todel:
		del plantest.planbynames[time]
	if active.log.updated():
		print active.log
	'''
	for event in pygame.event.get():
		if event.type == pygame.KEYDOWN:
			if event.key == K_ESCAPE:
				#print plane1x.get_changes()#, map(plane1x.second_der, [i for i in range(2, len(plane1x.vals))])
				print active.log
				serve.done = True
				sys.exit(0)
		elif event.type == pygame.MOUSEBUTTONDOWN:
			if event.button == 1: #left button, select plane or package
				visobj = vis.screen_loc_to_obj(event.pos, chooser = plane_chooser)
				if visobj:
					selectedplane = visobj.obj
					selectedpackage = None
				else:
					visobj = vis.screen_loc_to_obj(event.pos, chooser = package_chooser)
					if visobj:
						selectedpackage = visobj.obj
						selectedplane = None
			elif event.button == 3: #right button, fly to city, load to plane
				if selectedplane:
					visobj = vis.screen_loc_to_obj(event.pos, chooser = city_chooser)
					if visobj:
						domain.add_action(planes.flyop, [selectedplane, visobj.obj])
				elif selectedpackage:
					visobj = vis.screen_loc_to_obj(event.pos, chooser = plane_chooser)
					if visobj:
						domain.add_action(planes.loadop, [selectedpackage, visobj.obj])
					else:
						visobj = vis.screen_loc_to_obj(event.pos, chooser = city_chooser)
						if visobj:
							if selectedpackage.container.type == "plane":
								domain.add_action(planes.unloadop, [selectedpackage])
				
