({
	startGeneration : function(component, event, helper) {
		var action = component.get("c.generateAllMensualites");
        action.setCallback(this, function(response) {
            console.log('startGeneration ' + response.getState());
            var toastEvent = $A.get("e.force:showToast");
            if(component.isValid() && response.getState() === "SUCCESS") {
                toastEvent.setParams({
                    title: "Génération des mensualités",
                    message: "Génération des mensualités de l'année courante en cours, ceci peut prendre un certain temps...",
                    duration: '7000',
                    key: 'info_alt',
                    type: 'success',
                    mode: 'pester'
                });
            } else {
                toastEvent.setParams({
                    title: "Génération des mensualités",
                    message: "La génération des mensualités n'a pas pu être lancé...",
                    duration: '7000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
            }
            toastEvent.fire();
        }); 
        $A.enqueueAction(action);
	}
})