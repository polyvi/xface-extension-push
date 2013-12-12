describe('PushNotification (xFace.PushNotification)', function () {
   it("pushnotification.spec.1 should exist", function() {
        expect(xFace.PushNotification).toBeDefined();
    });

    it("pushnotification.spec.2 should contain proper functions", function() {
        expect(xFace.PushNotification.getDeviceToken).toBeDefined();
        expect(typeof xFace.PushNotification.getDeviceToken).toBe('function');
        expect(xFace.PushNotification.registerOnReceivedListener).toBeDefined();
        expect(typeof xFace.PushNotification.registerOnReceivedListener).toBe('function');
    });
});
