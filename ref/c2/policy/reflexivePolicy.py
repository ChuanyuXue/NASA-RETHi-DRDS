r''' Reflexive Policy Maker for MCVT
By - Murali Krishnan R
'''
import numpy as np

class SolarPVPolicy:
	def __init__(self, category, threshold):
		self.category = category
		self.threshold = threshold
		self.act_id = 1

	def is_act_performed(self, b_agnt_acts):
		if self.act_id in b_agnt_acts:
			return True
		else:
			return False

	def act(self, b_fdd_data, b_agnt_data):
		'''Decide on intervention action given
		a) FDD data, b) Agent action information
		'''
		av_fdd_data = np.mean(b_fdd_data, axis=0)
		max_idx = np.argmax(av_fdd_data)
		max_prob = av_fdd_data[max_idx]
		cat_prob = av_fdd_data[self.category-1]
		pred_cat = max_idx + 1
		
		if pred_cat == self.category and max_prob >= self.threshold:
			# Sub-system is faulty
			act_performed = self.is_act_performed(b_agnt_data)
			if not act_performed:
				command = self.act_id
			else:
				command = -1.0
		else:
			command = -1.0

		intervention = "Idle" if command == -1.0 else "Repair SPG"
		print("[*] Solar-PV Dust \033" + \
			" Pr[Cat={}] = {:0.3f}%".format(self.category, cat_prob*100) + \
			f"Recommended Intervention: {intervention}")
		return command, cat_prob

	def act_mod(self, b_fdd_data, b_agnt_data):
		av_fdd_data = np.mean(b_fdd_data, axis=0)
		max_idx = np.argmax(av_fdd_data)
		pred_cat = max_idx + 1
		max_prob = av_fdd_data[max_idx]
		cat_prob = av_fdd_data[self.category-1]
		

		rule1 = (pred_cat == self.category) and (max_prob >= self.threshold)
		rule2 = pred_cat > self.category

		if rule1 or rule2:
			# Sub-system is faulty
			act_performed = self.is_act_performed(b_agnt_data)
			if not act_performed:
				command = self.act_id
			else:
				command = -1.0
		else:
			command = -1.0

		str1 = " Pr[Cat={}] = {:0.3f} % ".format(self.category, cat_prob*100)
		str2 = " Pr[Max Cat={}] = {:0.3f} % ".format(pred_cat, max_prob*100)

		print("[*] Solar-PV \033" + \
			str1 + \
			str2 + \
			f", Recommended Intervention: {command}")
		
		return command, cat_prob



class ECLSSPolicy:
	def __init__(self, fault_name, threshold):
		assert fault_name in ['dust', 'paint'], \
		f"[!] ECLSS fault {fault_name} not supported!"
		self.faultyThreshold = threshold
		self.fault_name = fault_name
		if self.fault_name == 'dust':
			self.act_id = 2
			self.repair_name = "Repair ECLSS Dust"
		elif self.fault_name == 'paint':
			self.act_id = 3
			self.repair_name = "Repair ECLSS Paint"

	def is_act_performed(self, b_agnt_acts):
		if self.act_id in b_agnt_acts:
			return True
		else:
			return False

	def act(self, b_fdd_data, b_agnt_data):
		m_prob = np.mean(b_fdd_data, axis=0)
		exp_faulty_panels = np.sum(m_prob)
		if exp_faulty_panels > self.faultyThreshold:
			# Sub-system is faulty
			act_performed = self.is_act_performed(b_agnt_data)
			if not act_performed:
				command = self.act_id
			else:
				command = -1.0
		else:
			command = -1.0
		intervention = "Idle" if command == -1.0 else self.fault_name
		print(f"[*] ECLSS ({self.fault_name}) \033 " + \
			"Exp[Num Faulty Panels] = {:0.3f}, ".format(exp_faulty_panels) + \
			f"Recommended Intervention: {intervention}")
		return command, exp_faulty_panels

	def act_mod(self, b_fdd_data, b_agnt_data):
		panelFaultyThresh = 0.5
		faulty_panels = np.greater_equal(b_fdd_data, panelFaultyThresh)
		exp_panel_dmg = np.mean(faulty_panels, axis=0)
		exp_faulty_panels = np.sum(exp_panel_dmg)
		if exp_faulty_panels >= self.faultyThreshold:
			# Sub-system is faulty
			act_performed = self.is_act_performed(b_agnt_data)
			if not act_performed:
				command = self.act_id
			else:
				command = -1.0
		else:
			command = -1.0

		print(f"[*] ECLSS ({self.fault_name}) \033 " + \
			"Exp[Num Faulty Panels] = {:0.3f}, ".format(exp_faulty_panels) + \
			f"Recommended Intervention: {command}")
		return command, exp_faulty_panels

class StructurePolicy:
	def __init__(self, threshold):
		self.threshold = threshold
		self.act_id = 4
	def is_act_performed(self, b_agnt_acts):
		if self.act_id in b_agnt_acts:
			return True
		else:
			return False


	def act(self, b_fdd_data, b_agnt_data):
		m_prob = np.mean(b_fdd_data, axis=0).item()
		if m_prob > self.threshold:
			# Sub-system is faulty
			act_performed = self.is_act_performed(b_agnt_data)
			if not act_performed:
				command = self.act_id
			else:
				command = -1.0
		else:
			command = -1.0

		intervention = "Idle" if command == -1.0 else "Repair Structure"
		print(f"[*] Structure Damage\033 " + \
			"Pr[Damage] = {:0.3f}%".format(m_prob*100) + \
			f"Recommended Intervention: {intervention}")
		return command, m_prob

class NPGPolicy:
	def __init__(self, threshold):
		self.threshold = threshold
		self.act_id = 5

	def is_act_performed(self, b_agnt_acts):
		if self.act_id in b_agnt_acts:
			return True
		else:
			return False

	def act(self, b_fdd_data, b_agnt_data):
		mean_data = np.mean(b_fdd_data, axis=0)

		if mean_data >= self.threshold:
			# Sub-system is faulty
			act_performed = self.is_act_performed(b_agnt_data)
			if not act_performed:
				command = self.act_id
			else:
				command = -1.0
		else:
			command = -1.0

		intervention = "Idle" if command == -1.0 else "Repair NPG" 
		print(f"[*] Nuclear Generator Dust, " + \
			"Exp[Damage] = {:0.3f}".format(mean_data.item()) + \
			f", Recommended intervention: {intervention}")

		return command, mean_data
